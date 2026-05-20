// Configuration for AWS services

const appConfig = {
    // AWS Cognito configuration
    cognito: {
        userPoolId: '${user_pool_id}', 
        userPoolClientId: '${user_pool_client_id}', 
        domain: '${cognito_domain}',
        region: 'us-east-1' 
    },
    // API Gateway configuration
    api: {
        baseUrl: '${api_endpoint}'
    }
};

window.appConfig = appConfig;