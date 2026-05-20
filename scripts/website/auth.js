document.addEventListener('DOMContentLoaded', () => {
    let isLoginMode = true;
    let cognitoUser = null;

    // Check if user is already logged in
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
        const currentUser = userPool.getCurrentUser();
        if (currentUser != null) {
            currentUser.getSession((err, session) => {
                if (!err && session.isValid()) {
                    window.location.href = 'vault.html'; // Redirect to vault if already logged in
                }
            });
        }
    }

    // Check URL params for mode
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('mode') === 'signup') {
        isLoginMode = false;
    }

    // --- DOM Elements ---
    const authTitle = document.getElementById('auth-title');
    const authForm = document.getElementById('auth-form');
    const emailGroup = document.getElementById('email-group');
    const usernameInput = document.getElementById('username');
    const emailInput = document.getElementById('email');
    const passwordInput = document.getElementById('password');
    const authSubmitBtn = document.getElementById('auth-submit-btn');
    const authSwitchText = document.getElementById('auth-switch-text');
    const authError = document.getElementById('auth-error');

    const verifyBox = document.getElementById('verify-box');
    const verifyForm = document.getElementById('verify-form');
    const verifyCodeInput = document.getElementById('verify-code');
    const verifyError = document.getElementById('verify-error');

    function updateUI() {
        authError.textContent = '';
        if (isLoginMode) {
            authTitle.textContent = 'Sign In';
            emailGroup.classList.add('hidden');
            authSubmitBtn.textContent = 'Sign In';
            authSwitchText.innerHTML = `Don't have an account? <a href="#" id="switch-to-signup">Sign Up</a>`;
        } else {
            authTitle.textContent = 'Create Account';
            emailGroup.classList.remove('hidden');
            authSubmitBtn.textContent = 'Sign Up';
            authSwitchText.innerHTML = `Already have an account? <a href="#" id="switch-to-signup">Sign In</a>`;
        }
        
        document.getElementById('switch-to-signup').addEventListener('click', (e) => {
            e.preventDefault();
            isLoginMode = !isLoginMode;
            updateUI();
        });
    }

    updateUI();

    // Auth Form Submit
    authForm.addEventListener('submit', (e) => {
        e.preventDefault();
        authError.textContent = '';
        
        const username = usernameInput.value.trim();
        const password = passwordInput.value;

        if (!userPool) {
            authError.textContent = "Error: Authentication system is not configured. Please check your config.js or ensure Terraform deployment completed successfully.";
            return;
        }

        authSubmitBtn.disabled = true;
        authSubmitBtn.textContent = 'Please wait...';

        if (isLoginMode) {
            // LOGIN
            const authenticationDetails = new AmazonCognitoIdentity.AuthenticationDetails({
                Username: username,
                Password: password,
            });

            cognitoUser = new AmazonCognitoIdentity.CognitoUser({
                Username: username,
                Pool: userPool
            });

            cognitoUser.authenticateUser(authenticationDetails, {
                onSuccess: function (result) {
                    window.location.href = 'vault.html';
                },
                onFailure: function (err) {
                    authError.textContent = err.message || JSON.stringify(err);
                    resetAuthBtn();
                },
            });
        } else {
            // SIGNUP
            const email = emailInput.value.trim();
            const attributeList = [
                new AmazonCognitoIdentity.CognitoUserAttribute({ Name: 'email', Value: email })
            ];

            userPool.signUp(username, password, attributeList, null, function(err, result) {
                if (err) {
                    authError.textContent = err.message || JSON.stringify(err);
                    resetAuthBtn();
                    return;
                }
                cognitoUser = result.user;
                authForm.parentElement.classList.add('hidden');
                verifyBox.classList.remove('hidden');
            });
        }
    });

    // Verification Form Submit
    verifyForm.addEventListener('submit', (e) => {
        e.preventDefault();
        verifyError.textContent = '';
        const code = verifyCodeInput.value.trim();

        if (!cognitoUser) return;

        cognitoUser.confirmRegistration(code, true, function(err, result) {
            if (err) {
                verifyError.textContent = err.message || JSON.stringify(err);
                return;
            }
            alert('Verification successful! You can now sign in.');
            verifyBox.classList.add('hidden');
            authForm.parentElement.classList.remove('hidden');
            isLoginMode = true;
            updateUI();
        });
    });

    function resetAuthBtn() {
        authSubmitBtn.disabled = false;
        authSubmitBtn.textContent = isLoginMode ? 'Sign In' : 'Sign Up';
    }
});       verifyBox.classList.add('hidden');
            authForm.parentElement.classList.remove('hidden');
            isLoginMode = true;
            updateUI();
        });
    });

    function resetAuthBtn() {
        authSubmitBtn.disabled = false;
        authSubmitBtn.textContent = isLoginMode ? 'Sign In' : 'Sign Up';
    }
});