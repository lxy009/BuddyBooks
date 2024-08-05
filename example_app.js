
// sys
const path = require('path');
// 3p
const express = require('express');
// proj
// pkg


const PORT = 4001;

const app = express();
app.use(express.static('public'));



app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname + "/example_app.html"));
});


app.listen(PORT, () => console.log(`Example app listening on port ${PORT}!`));
