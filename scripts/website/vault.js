document.addEventListener('DOMContentLoaded', () => {
    let currentUser = null;
    let cognitoUser = null;
    let authSession = null;

    // Cognito Setup
    const poolData = {
        UserPoolId: appConfig.cognito.userPoolId,
        ClientId: appConfig.cognito.userPoolClientId
    };
    
    let userPool = null;
    const isConfigured = appConfig.cognito.userPoolId && 
                         !appConfig.cognito.userPoolId.includes('${') && 
                         !appConfig.cognito.userPoolId.includes('REGION_');

    if (typeof AmazonCognitoIdentity !== 'undefined' && isConfigured) {
        userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);
    }

    // --- DOM Elements ---
    const welcomeMessage = document.getElementById('welcome-message');
    const logoutBtn = document.getElementById('logout-btn');
    
    const fileUpload = document.getElementById('file-upload');
    const selectedFileName = document.getElementById('selected-file-name');
    const uploadBtn = document.getElementById('upload-btn');
    const uploadProgress = document.getElementById('upload-progress');
    const progressFill = document.getElementById('progress-fill');
    const progressText = document.getElementById('progress-text');
    const fileListBody = document.getElementById('file-list-body');

    // --- Initialization ---
    checkAuthStatus();

    // --- Functions ---
    function checkAuthStatus() {
        if (userPool) {
            cognitoUser = userPool.getCurrentUser();
            if (cognitoUser != null) {
                cognitoUser.getSession(function(err, session) {
                    if (err) {
                        window.location.href = 'auth.html';
                        return;
                    }
                    authSession = session;
                    currentUser = cognitoUser.getUsername();
                    initVault();
                });
            } else {
                window.location.href = 'auth.html';
            }
        } else {
            // Mock Mode Check
            const mockUser = sessionStorage.getItem('mockUser');
            if (mockUser) {
                currentUser = mockUser;
                authSession = { getIdToken: () => ({ getJwtToken: () => 'mock-token' }) };
                initVault();
            } else {
                window.location.href = 'auth.html';
            }
        }
    }

    function initVault() {
        welcomeMessage.textContent = `Welcome, ${currentUser}`;
        loadFiles();
    }

    // Logout
    logoutBtn.addEventListener('click', () => {
        // 1. Clear Cognito SDK session
        if (userPool) {
            const user = userPool.getCurrentUser();
            if (user) {
                user.signOut();
            }
        }

        // 2. Clear all local and session storage
        sessionStorage.clear();
        localStorage.clear();
        
        // 3. Handle Cognito Hosted UI Logout if configured
        if (appConfig.cognito.domain && 
            !appConfig.cognito.domain.includes('${') && 
            !appConfig.cognito.domain.includes('REGION_')) {
            
            const clientId = appConfig.cognito.userPoolClientId;
            // Use current origin for logout URI
            const logoutUri = encodeURIComponent(`${window.location.origin}/index.html`);
            const cognitoLogoutUrl = `https://${appConfig.cognito.domain}/logout?client_id=${clientId}&logout_uri=${logoutUri}`;
            
            window.location.href = cognitoLogoutUrl;
        } else {
            // Default redirect for local/mock development
            window.location.href = 'index.html';
        }
    });

    // File Selection
    fileUpload.addEventListener('change', (e) => {
        if (e.target.files.length > 0) {
            const file = e.target.files[0];
            selectedFileName.textContent = file.name;
            uploadBtn.disabled = false;
        } else {
            selectedFileName.textContent = 'No file selected';
            uploadBtn.disabled = true;
        }
    });

    // Upload File
    uploadBtn.addEventListener('click', async () => {
        const file = fileUpload.files[0];
        if (!file) return;

        uploadBtn.disabled = true;
        uploadProgress.classList.remove('hidden');
        progressFill.style.width = '10%';
        progressText.textContent = 'Getting upload URL...';

        try {
            const presignedData = await getPresignedUrl(file.name, file.type);
            progressFill.style.width = '30%';
            progressText.textContent = 'Uploading to S3...';

            await uploadToS3(presignedData.uploadUrl, file);
            progressFill.style.width = '90%';
            progressText.textContent = 'Finalizing...';

            await recordFileMetadata(file.name, file.size);
            progressFill.style.width = '100%';
            progressText.textContent = 'Complete!';
            
            setTimeout(() => {
                uploadProgress.classList.add('hidden');
                fileUpload.value = '';
                selectedFileName.textContent = 'No file selected';
                uploadBtn.disabled = true;
                loadFiles();
            }, 2000);
        } catch (error) {
            console.error("Upload error:", error);
            progressText.textContent = 'Upload failed!';
            progressFill.style.backgroundColor = 'var(--danger-color)';
            setTimeout(() => {
                uploadProgress.classList.add('hidden');
                progressFill.style.backgroundColor = 'var(--primary-color)';
                uploadBtn.disabled = false;
            }, 3000);
        }
    });

    function getAuthToken() {
        if (authSession && authSession.isValid()) {
            return authSession.getIdToken().getJwtToken();
        }
        return sessionStorage.getItem('idToken') || '';
    }

    // API Interactions
    async function loadFiles() {
        fileListBody.innerHTML = '<tr><td colspan="4" class="empty-state">Loading your files...</td></tr>';
        try {
            const apiUrl = `${appConfig.api.baseUrl}/files`;
            let files = [];

            if (appConfig.api.baseUrl.includes('YOUR_API_GATEWAY_ID')) {
                await new Promise(resolve => setTimeout(resolve, 800));
                files = [
                    { id: '1', name: 'secret_document.pdf', size: 1048576, uploadedAt: new Date().toISOString() },
                    { id: '2', name: 'financial_report.xlsx', size: 524288, uploadedAt: new Date(Date.now() - 86400000).toISOString() }
                ];
            } else {
                const response = await fetch(apiUrl, {
                    method: 'GET',
                    headers: { 'Authorization': `Bearer ${getAuthToken()}` }
                });
                if (!response.ok) throw new Error('Failed to fetch files');
                files = await response.json();
            }
            renderFileList(files);
        } catch (error) {
            console.error("Error loading files:", error);
            fileListBody.innerHTML = '<tr><td colspan="4" class="empty-state" style="color:var(--danger-color)">Failed to load files.</td></tr>';
        }
    }

    function renderFileList(files) {
        if (!files || files.length === 0) {
            fileListBody.innerHTML = '<tr><td colspan="4" class="empty-state">Your vault is empty. Upload a file securely.</td></tr>';
            return;
        }

        fileListBody.innerHTML = '';
        files.forEach(file => {
            const tr = document.createElement('tr');
            const date = new Date(file.uploadedAt).toLocaleDateString() + ' ' + new Date(file.uploadedAt).toLocaleTimeString();
            const sizeStr = formatBytes(file.size);

            tr.innerHTML = `
                <td>${file.name}</td>
                <td>${sizeStr}</td>
                <td>${date}</td>
                <td class="action-links">
                    <a href="#" onclick="downloadFile('${file.id}', '${file.name}'); return false;">Download</a>
                    <a href="#" style="color: var(--danger-color);" onclick="deleteFile('${file.id}'); return false;">Delete</a>
                </td>
            `;
            fileListBody.appendChild(tr);
        });
    }

    async function getPresignedUrl(fileName, fileType) {
        if (appConfig.api.baseUrl.includes('YOUR_API_GATEWAY_ID')) {
            return new Promise(resolve => setTimeout(() => resolve({ uploadUrl: 'mock-url' }), 500));
        }

        const response = await fetch(`${appConfig.api.baseUrl}/files/upload-url`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${getAuthToken()}`
            },
            body: JSON.stringify({ fileName, fileType })
        });
        if (!response.ok) throw new Error('Failed to get presigned URL');
        return await response.json();
    }

    async function uploadToS3(presignedUrl, file) {
        if (presignedUrl === 'mock-url') {
            return new Promise((resolve) => {
                let p = 30;
                const interval = setInterval(() => {
                    p += 10;
                    progressFill.style.width = p + '%';
                    if (p >= 90) {
                        clearInterval(interval);
                        resolve();
                    }
                }, 200);
            });
        }

        const response = await fetch(presignedUrl, {
            method: 'PUT',
            body: file,
            headers: { 'Content-Type': file.type }
        });
        if (!response.ok) throw new Error('S3 Upload Failed');
    }

    async function recordFileMetadata(fileName, fileSize) {
        if (appConfig.api.baseUrl.includes('YOUR_API_GATEWAY_ID')) return;
        await fetch(`${appConfig.api.baseUrl}/files`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${getAuthToken()}`
            },
            body: JSON.stringify({ fileName, size: fileSize })
        });
    }

    window.downloadFile = async function(fileId, fileName) {
        try {
            if (appConfig.api.baseUrl.includes('YOUR_API_GATEWAY_ID')) {
                alert(`Mock Download: ${fileName}`);
                return;
            }
            const response = await fetch(`${appConfig.api.baseUrl}/files/${fileId}/download-url`, {
                headers: { 'Authorization': `Bearer ${getAuthToken()}` }
            });
            if (!response.ok) throw new Error('Failed to get download URL');
            const data = await response.json();
            
            const a = document.createElement('a');
            a.href = data.downloadUrl;
            a.download = fileName;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
        } catch (error) {
            console.error("Download error:", error);
            alert("Failed to download file.");
        }
    };

    window.deleteFile = async function(fileId) {
        if (!confirm('Are you sure you want to delete this file?')) return;
        try {
            if (appConfig.api.baseUrl.includes('YOUR_API_GATEWAY_ID')) {
                alert(`Mock Delete: File ID ${fileId}`);
                loadFiles();
                return;
            }
            const response = await fetch(`${appConfig.api.baseUrl}/files/${fileId}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${getAuthToken()}` }
            });
            if (!response.ok) throw new Error('Failed to delete file');
            loadFiles();
        } catch (error) {
            console.error("Delete error:", error);
            alert("Failed to delete file.");
        }
    };

    function formatBytes(bytes, decimals = 2) {
        if (!+bytes) return '0 Bytes';
        const k = 1024;
        const dm = decimals < 0 ? 0 : decimals;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
    }
});