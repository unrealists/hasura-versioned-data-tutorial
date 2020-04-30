# Version your data like a boss using Hasura

Have you ever lost a critical data due to overwrite? Such a silly question... of course you did. This is the nasty side effect of `U` in `CRUD`. It is not a design flaw. Update operation is meant to replace you existing data. Hence, it is very valid a common use case. 

Most common attempts to mitigate such problem might be limiting. A naive but brave suggestion mostly suggests not to allow access to the DB.

    
    Problem: Prevent accidental updates/deletes on any table

    solution: Easy solution: DONT ALLOW DEVS ACCESS TO PROD!!! We are evil breakers of all things production.

    <img src="./just-dont-do-it.png" height=400 >



You read it right, `it is easy piezy, just don do it bro!` 
