:warning: [ as of MATLAB>2021a, `jsonencode` itself supports pretty printing](https://nl.mathworks.com/matlabcentral/answers/478932-convert-struct-to-readable-json-pretty-print#answer_884815)

# prettyjson.m [![View prettyjson.m on MATLAB File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://nl.mathworks.com/matlabcentral/fileexchange/72667-prettyjson-m)

Basic function to make JSON strings formatted by MATLAB's built-in `jsonencode.m` more readable. 
Mostly meant for structures with simple strings and arrays; gets confused and **mangles** JSON when strings contain `[` `]` `{` or `}`. 

Example: the following [mess](https://gist.github.com/tlongren/7697704d62f26235661e)

```
{"items":[{"address":"someemail1@yahoo.com","code":"554","error":"554 delivery error: dd This user doesn't have a yahoo.com account (someemail1@yahoo.com) **removed brackets here** - mta1481.mail.ne1.yahoo.com","created_at":"Thu, 07 May 2015 23:07:47 UTC"},{"address":"someemail2@gmail.com","code":"550","error":"550 5.1.1 The email account that you tried to reach does not exist. Please try\n5.1.1 double-checking the recipient's email address for typos or\n5.1.1 unnecessary spaces. Learn more at\n5.1.1 http://support.google.com/mail/bin/answer.py?answer=6596 xv3si12818843vdb.43 - gsmtp","created_at":"Sun, 03 May 2015 13:22:49 UTC"},{"address":"someemail3@domain.com","code":"550","error":"550 No Such User Here","created_at":"Thu, 02 Jul 2015 17:01:31 UTC"},{"address":"someemail4@domain.com","code":"550","error":"550 Administrative prohibition","created_at":"Thu, 21 May 2015 03:30:38 UTC"}],"paging":{"first":"https://api.mailgun.net/v3/mg.yourdomain.com/bounces?limit=100","last":"https://api.mailgun.net/v3/mg.yourdomain.com/bounces?page=last\u0026limit=100","next":"https://api.mailgun.net/v3/mg.yourdomain.com/bounces?page=next\u0026address=someemail4%40domain.com\u0026limit=100","previous":"https://api.mailgun.net/v3/mg.yourdomain.com/bounces?page=previous\u0026address=someemail1%40yahoo.com\u0026limit=100"}}
```

becomes

```
{
    "items":[
        {
            "address":"someemail1@yahoo.com", 
            "code":"554", 
            "error":"554 delivery error: dd This user doesn't have a yahoo.com account (someemail1@yahoo.com) **removed brackets here** - mta1481.mail.ne1.yahoo.com", 
            "created_at":"Thu, 07 May 2015 23:07:47 UTC"
        }, 
        {
            "address":"someemail2@gmail.com", 
            "code":"550", 
            "error":"550 5.1.1 The email account that you tried to reach does not exist. Please try\n5.1.1 double-checking the recipient's email address for typos or\n5.1.1 unnecessary spaces. Learn more at\n5.1.1 http://support.google.com/mail/bin/answer.py?answer=6596 xv3si12818843vdb.43 - gsmtp", 
            "created_at":"Sun, 03 May 2015 13:22:49 UTC"
        }, 
        {
            "address":"someemail3@domain.com", 
            "code":"550", 
            "error":"550 No Such User Here", 
            "created_at":"Thu, 02 Jul 2015 17:01:31 UTC"
        }, 
        {
            "address":"someemail4@domain.com", 
            "code":"550", 
            "error":"550 Administrative prohibition", 
            "created_at":"Thu, 21 May 2015 03:30:38 UTC"
        }
    ], 
    "paging":{
        "first":"https://api.mailgun.net/v3/mg.yourdomain.com/bounces?limit=100", 
        "last":"https://api.mailgun.net/v3/mg.yourdomain.com/bounces?page=last\u0026limit=100", 
        "next":"https://api.mailgun.net/v3/mg.yourdomain.com/bounces?page=next\u0026address=someemail4%40domain.com\u0026limit=100", 
        "previous":"https://api.mailgun.net/v3/mg.yourdomain.com/bounces?page=previous\u0026address=someemail1%40yahoo.com\u0026limit=100"
    }
}
```
