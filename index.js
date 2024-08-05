

// sys
const fs = require('fs').promises;
// 3p
const express = require('express');
// proj
// pkg


const app = express();
app.use(express.json());


// journal -----------------

const journal = [];

const connect_journal = async function() {
    // placeholder -- files only, no data store etc.
    const files = await fs.readdir("data/");
    files.forEach( async (file) => {
        journal.push(JSON.parse(await fs.read(file)));
    });
}

const assign_transaction_id = function() {
    // placeholder -- files only,
    const ids = journal.map( entry => entry.id);
    return Math.max(...idx) + 1;
};

const validate_entry = function(entry) {
    return {
        valid: true,
        entry: JSON.parse(entry)   
    };
};

const record_new_journal_entry = function(entry) {
    return fs.writeFile(
        file = entry.id + ".json",
        data = JSON.stringify(entry, null, 2)
    );
};

// routes -----------------

app.route('/journal')
    .get( (req, res) => {
        res.send('POST json')
    })
    .post( (req, res) => {
        //assign transaction ID
        const new_id = assign_transaction_id();
        //validation
        const validated = validate_entry(req.body);
        if (validated.valid) {
            const new_entry = Object.assign( {id: new_id}, validated.entry );
            //record to cache
            journal.push(new_entry);
            //record entry
            record_new_journal_entry(new_entry)
                .then( res => {
                    res.status(200).send({status: "success"});
                })
                .catch( e => {
                    journal.pop();
                    console.log('issue with recording new entry');
                    console.log(e);
                });
        } else {
            res.status(500).send({status: "error"});
        }
    });

// app.route('/journal')
//     .get((req, res) => {
//         res.send('GET /account/:account_name');
//     })
//     .post((req, res) => {
//         console.log(req.body);
//         let http_status = 500;
//         let success = false;
//         createPerson(req.body)
//             .then(results => {
//                 http_status = 201;
//                 success = true;
//             }).catch(error => {
//                 console.log(error);
//             }).finally(() => {
//                 writeLogs("create_person", req.body, success);
//                 res.status(http_status).send({ "success": success });
//             });
//     }); 



// app.route('/account/:account_name')
//     .get((req, res) => {
//         const acct = req.params.account_name;
//         let account = {};
//         let http_status = 500;
//         findAccount(acct)
//             .then(res => {
//                 account = res;
//                 http_status = 200;
//             })
//             .catch(e => {
//                 console.log(e);
//             })
//             .finally(() => {
//                 res.status(http_status).send(account);
//             });
//     })
//     .post((req, res) => {
//         console.log(req.body);
//         let http_status = 500;
//         let success = false;
//         const log_entry = JSON.parse(JSON.stringify(req.body));
//         log_entry.name = req.params.account_name;
//         try {
//             updateAccount(req.params.account_name, req.body);
//             http_status = 201;
//             success = true;
//         } catch (e) {
//             console.log(e);
//         } finally {
//             writeLogs("update_account", log_entry, success);
//             res.status(http_status).send({ note: 'good' });
//         }
//     }); 

module.exports.start = function(port, cb) {
    connect_journal()
        .then( res => {
            app.listen(port, cb);
        })
        .catch( e => {
            console.log('error in starting server');
            console.log(e);
        });
};
