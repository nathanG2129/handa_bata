const fs = require('fs');
const path = require('path');

// Create lib directory if it doesn't exist
if (!fs.existsSync('lib')) {
    fs.mkdirSync('lib');
}

// Copy service-account.json to lib directory
fs.copyFileSync(
    path.join(__dirname, 'service-account.json'),
    path.join(__dirname, 'lib', 'service-account.json')
); 