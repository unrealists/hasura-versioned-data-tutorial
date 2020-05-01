#  Version your data and serve it via realtime API<sup>*</sup>
###### <sup>*</sup>like a boss

This is going to be a bit long but I think it really matters that you understand where my intentions are coming from...


## Problem

Have you ever lost a critical data due to overwrite? Such a silly question... of course you did. This is the nasty side effect of `U` in `CRUD`. It is not a design flaw. Update operation is meant to replace you existing data. Hence, it is very valid a common use case.
Most common attempts to mitigate such problem might be limiting. A naive but brave suggestion mostly suggests not to allow access to the DB.

    Problem: Prevent accidental updates/deletes on any table

    Solution: Easy solution: DONT ALLOW DEVS ACCESS TO PROD!!! We are evil breakers of all things production.

![](./1.png)
source: https://stackoverflow.com/questions/14438055/prevent-accidental-updates-deletes-on-any-table

You read it right, `it is easy piezy, just don't do it bro!`. Probably, you have got such advice as well. Let our hero, `MGOwen` speak for all of us: `If "just don't ever make mistakes" was a valid argument, we wouldn't need seatbelts and firearm safety switches`.

## Premise

What if preventing update is not an option? Let's go even more extreme and embrace updating sensitive data everywhere including in production. Imagine that your system requires applications to perform and an update but still need to keep track of every goddamn change ever happened to data.

Welcome to my world, ladies, gentlemen and other gender members. I spend most of my career dealing with fintechs and finance companies in general. There is one capability you **must have** as a financial service provider. ***Every action must be logged alongside with corresponding data. Otherwise, you liable for any financial crime occuring at your platform.*** This is the way of fintech life, you have to suck it in. 

`'So what? It is not rocket science'`, I hear you saying.  You are right. That is not rocket science. I mean, let me be honest, I have found many different ways to mitigate this problem in the past. There are myriad of ways to implement a platform with a versioned data model. That is not the point. It is the cost(both time, money ) of such implementations often gives start-up a big smack in the face when they have to be agile. You see your friends enjoying building shiny new APIs backed by simple CRUD systems and start their start-up journey months ahead while you fight with f..ck ton of quirky data models to offer a brand new finance app to the brave new world while regulators are stalking you. 


## Search for a safe heaven with my buddy, Postgres

Back in the days, I semi-successfully co-founded a Business Intelligence SaaS company. There, my obsession was(and still is) to look for how databases work. Out of all aspects of DBs, I was mostly interested in how they treat SQL. I love any database that has first class SQL support. When my friends were trying to shame me due to my loyalty towards SQL and skepticism towards new age NoSQL conventions, I was throwing back at them my buddy Postgres. Its use of SQL and modular architecture with a rock solid stability(and oc course, performance) was keeping NoSQL fanboys at bay. But they were still shouting outside. 

**'Good luck with wasted resources on developing cool APIs on top of your DB from 90ies'**

I saw people developing kickass applications with extreme interactivity using Firebase, RethinkDB and co.. served behind a shiny cool API like GraphQL ,consumed by even shinier patterns like redux. These guys were cool guys. To be fair, they looked cool too. It was not gimmick. I was dreaming to have company where I could build a kick ass finance product with such tech stack. Last fintech company I co-founded, was my stage to show world that I can also do such stuff with Postgres without hiring half of developers in Berlin. Well, **NOPE**, it did not happen. Even if we used GraphQL, providing reactive API aka `Subcriptions` backed by traditional Database(***with versioned data structures***) is really harder than I imagined.

 I almost gave up and even cheated my beloved Postgres with Firebase. I'm not going to comment on that experience much but here is what I get to say about it: `it ended up being a huge dissapointment and regret`. It is a beast(!) that can't perform a basic [logical  `OR`  operation](https://stackoverflow.com/questions/46726673/firebase-firestore-or-query) in 2020. let that sink in...

I was desperate...

##  A Hero that I have not ask for...

GraphQL `Subscriptions`  defined my search criteria. After much struggle, I started to look for a solution that provides real-time interactivity on top of **my very own data model** with minimal effort. Remember, I want to have all bells and whistles of reactive world without sacrificing a custom data model that provides built in versioning. I know I ask a lot. But who cares, I am a dreamer. 

First, my friends pointed me towards another Berlin based start-up called graph.cool and their baby product called `Prisma`. It was a very compelling product. It almost got me using it. At that time(early 2019), their support for `Subscription` when data is nested, was tricky. Besides all, I did not support my data layer it is not built by them. You can imagine that my old buddy Postgres can do wonders in terms of how flexible you can model your data layer. Prisma was having none of it.

Then I saw Hasura. It was too good to be true. They were claiming that any possible query you can come up with can also be a subscription. Moreover, **this is where they got me in**, Hasura supported your very own data model. As if this is not enough, they had very promising permissin system where I could build RBAC model using JWT ( This aspect is another killer feature alone but not going to talk about it today, here some nice sources that inspired me [1](https://dev.to/lineup-ninja/modelling-teams-and-user-security-with-hasura-204i)[, 2)](https://hasura.io/blog/access-control-patterns-with-hasura-graphql-engine/). All of these features can be done with minimal or zero coding.

So I wanted to give it a try. 

##  A glimpse into my joy

I will be way more quick with this one. I want, _very quickly and simply_, to show you that what I am capable of doing with this badboy. So don't whine to me that this example is too simple. You can do way more than what I am about to show you.  Here we go...

Imagine a graphQL API that:
- versions any change you can do to a database table
- lets you see all historical versions along side with current version
- recovers data even if you delete
- offers a direct graphql API with impressive(IMHO, best in class) query capabilities
- this API is realtime.
- only with Hasura and SQL(plus, of course, docker duuh!).

#### 0- Start hasura and postgres
run these commands and go to your browser and type `http://localhost:8080/`
```
 $wget https://raw.githubusercontent.com/hasura/graphql-engine/stable/install-manifests/docker-compose/docker-compose.yaml
 $docker-compose up -d
```
have questions? Not my problem. I'm here to tell my story. follow this [link](https://hasura.io/docs/1.0/graphql/manual/getting-started/docker-simple.html) if you ever fail to run a simple docker-compose command...

#### 1- Meet our _versioned_ table: Users
Here are features of this table that is crucial to me(regardless of actual content):
- User table has `id` (uuid) and `_id` (int) as identifiers. `_id` specificly holds version indentifier with in objects with same `id`. `id` is generated by default using `gen_random_uuid()` and `_id` has auto increment(`nextval('schema."<table><column>_seq"'::regclass)`).
- User lives with under a schema called `versioned`
![](./2.gif)

- User has a `created_at`(timestampz) field that has `now()`(current time) as default value.
- a boolean `deleted` field is added to mark record deletion. 



    a `data`(jsonb) field is added to represent a versioned content. There is no limit(except DB column limit) for how many columns you can add to the table. We don't care. All of these fields will be versioned. 

Here is a gif for you. Hasura Console is enough to create this table without any direct access to our beloved DB.

![](./3.gif)

Final table has following DDL:
```
create table "Users"
(
    id          uuid default gen_random_uuid()                    not null,
   _id          serial                                            not null
                constraint "Users_pkey"
                primary key,
    created_at timestamp with time zone default now()             not null,
    data       jsonb                                              not null,
    deleted    boolean
);
```



#### 2- Meet our view: Users
This part is the most tricky part of all. we need to create a `SQL View` to represent most current version of the user record sharing same `id` value. Additionally, we need to access `created_at` value of very first version of a user with same `id`. If *most recent* record has `deleted` with `true` as value, then we need to hide it so it doesnt appear in this layer.

Bear with me and take a look at this ugly query.

```
CREATE VIEW "Users"(_id, id, updated_at, data, created_at) as
WITH last_version AS (
    SELECT
       v._id,
       v.id,
       v.created_at AS updated_at,
       v.data
    FROM versioned."Users" v
    LEFT JOIN versioned."Users" v2 ON v._id < v2._id AND v.id = v2.id
    WHERE v2._id IS NULL AND v.deleted IS NULL
), first_version AS (
    SELECT
        v.id,
        v.created_at
    FROM versioned."Users" v
    LEFT JOIN versioned."Users" v2 ON v._id > v2._id AND v.id = v2.id
    WHERE v2._id IS NULL
     )
SELECT lv._id,
       lv.id,
       lv.updated_at,
       lv.data,
       fv.created_at
FROM last_version lv
LEFT JOIN first_version fv ON fv.id = lv.id;
```

Lets break this down:
- `last_version` and `first_version` are holds first and last version of a record with same `id`.
-  with `...ON v._id < v2._id AND v.id = v2.id` we perform a self join with recods with same `id` and greater`_id`(or smaller when `v._id > v2._id`). if particular record fails to join itself with given conditions, it implies that it is the latest record(or first one when ` v._id > v2._id`). Finally, we only select that edge record(first or last) with `WHERE v2._id IS NULL`
- `v.deleted IS NULL` is eliminates the record with given `id`, if last version is marked as deleted. 
- `last_version`'s `created_at` value is actually last update date for a record. So we alias this part using `v.created_at AS updated_at,`
- finally, we combine first and last value with
```
SELECT lv._id,
       lv.id,
       lv.updated_at,
       lv.data,
       fv.created_at
FROM last_version lv
LEFT JOIN first_version fv ON fv.id = lv.id;
```
This is one of many ways of retrieving `first/last value within group`. In real life I use more eloborate but more performant ways of doing same job. I just wanted to showcase what I meant with a simple example. Check out these links to get better idea about these patterns([1](https://thoughtbot.com/blog/ordering-within-a-sql-group-by-clause), [2](https://www.red-gate.com/simple-talk/sql/database-administration/sql-strategies-for-versioned-data/), [3](https://hakibenita.com/sql-group-by-first-last-value)). Internet is full of them.

Don't forget to add it to Hasura:
![](./4.png)

#### 3- Meet our relation: Versions
As I promised, our approach will **_let you see all historical versions along side with current version_**.
Hasura comes to our resque:
![](./5.gif)

Now we are able to reference each version of our record alongside with most recent one.



## Conclusion
Consider Hasura as a SQL generator engine for your GraphQL API. it is very powerful **single** layer for your application. investigating generated SQL query for given operation mostly enough to understand what is happening under the hood. This transparency is very rare to find for a product that provides such capabilities. However, for high stakes tasks, such as finance, utilizing very trivial use of [actions](https://hasura.io/docs/1.0/graphql/manual/actions/index.html) to control and enhance API layer is quite crucial. 

With this approach, you are only **inserting new records** to our DB. We must takeaway any `UPDATE`, `DELETE`, `TRUNCATE` privilages from operating DB user. Addition to that, Hasura, must limit access to corresponding mutations using various techniques such as [Whitelisting](https://hasura.io/docs/1.0/graphql/manual/deployment/allow-list.html), [Authorization & Access Control](https://hasura.io/docs/1.0/graphql/manual/auth/authorization/index.html). I haven't touched such aspects within scope of this tutorial. However, they are very powerful and useful abstraction mechanisms. 

That's it. We are done and let's enjoy out new API. Here is a glimpse of joyful use of realtime versioned api we have just created without wasted sprints by a team of engineers.


