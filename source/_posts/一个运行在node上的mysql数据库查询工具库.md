---
title: 一个运行在node上的mysql数据库查询工具库
date: 2017-06-23 16:46:17
comments: true
tags: [Nodejs, JavaScript, Mysql]
---

```javascript
    module.exports = function() {
        var mysqlobj = require('mysql');
        var async = require('async');

        var pool = mysqlobj.createPool({
            host: 'host',
            user: 'user',
            password: 'password',
            database: "databases",
            //debug: true,
        });
        return {
            pool:pool,
            query:function(sql, param, callback){
                if(typeof param == "function"){
                    callback = param;
                    param = [];
                }
                pool.getConnection(function(err, connection) {
                    if(err){
                        callback(err, [])
                        return;
                        
                    }
                    try{
                        connection.query( sql, param, function(err, rows) {
                            connection.release();
                            callback(err, rows)
                        });
                    }
                    catch(e){
                        console.log("数据库查询出错了："+sql);
                        console.log(param);
                        console.log(e);
                        
                        callback("err", null)
                    }
                });
            },
            /*
            sqlParamsArr:[
                {
                    sql:"update table set .......",
                    params:[p1,p2],
                }
            ]
            */
            startTransaction:function(sqlParamsArr, callback){
                pool.getConnection(function(err, connection) {
                    if(err){
                        callback(err, [])
                        return;
                    }
                    
                    asyncCallFunctionList = [];
                    for(var i=0; i<sqlParamsArr.length; i++){
                        asyncCallFunctionList.push(function(ii){
                            return function(callbackInner){
                                connection.query(sqlParamsArr[ii].sql,sqlParamsArr[ii].params , callbackInner);
                            }
                        }(i));
                    }
                    
                    try{
                        
                        
                        connection.beginTransaction(function(err) {
                            if(err) {
                                callback("err");
                            }
                            async.series(asyncCallFunctionList, function(err, result) {
                                if(err) {
                                    connection.rollback(function() {
                                        callback("err");
                                    });
                                    return ;
                                }
                                // 提交事务
                                connection.commit(function(err) {
                                    if (err) { 
                                        connection.rollback(function() {
                                            callback("err");
                                        });
                                    }
                                    console.log('事务提交成功!');
                                    callback(null);
                                });
                            });
                    });
                    }
                    catch(e){
                        console.log("数据库查询出错了（事务处理）："+sqlParamsArr);
                        
                        console.log(e);
                        callback("err", null)
                    }
                });
            },
            execSql:function(sql, param, callback){
                
            }
        }
    }()
```