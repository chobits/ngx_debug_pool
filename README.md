ngx_debug_pool
==============

This module provides access to information of memory usage for nginx memory pool.

Example
=======

get information of worker process
---------------------------------

```
 http {
    server {
        listen 80;

        location = /debug_pool {
            debug_pool;
        }
    }
 }
```

Requesting URI /debug_pool, you will get information of memory usage for worker process which gets this request.  
The output page may look like as follows:

```
$ curl http://localhost:80/debug_pool
pid:1671
size:      502312 num:           6 cnum:           1 lnum:          31 ngx_init_cycle
size:           0 num:           1 cnum:           0 lnum:           0 ngx_http_spdy_keepalive_handler
size:        1536 num:         195 cnum:           1 lnum:        1635 ngx_event_accept
size:           0 num:          11 cnum:           0 lnum:           0 ngx_http_upstream_connect
size:           0 num:           1 cnum:           0 lnum:           0 ngx_http_lua_create_fake_request
size:           0 num:           1 cnum:           0 lnum:           0 main
size:           0 num:           1 cnum:           0 lnum:           0 ngx_http_lua_create_fake_connection
size:           0 num:           1 cnum:           0 lnum:           0 ngx_http_spdy_init
size:           0 num:           3 cnum:           0 lnum:          18 ngx_http_server_names
size:        8192 num:         810 cnum:           1 lnum:          11 ngx_http_create_request
size:           0 num:           1 cnum:           0 lnum:           0 ngx_http_lua_init_worker
size:       500KB num:        1031 cnum:           3 lnum:        1695 [SUMMARY]
```

get information of specific process
-----------------------------------

Also you can use gdb script `debug_pool.gdb` to get information of specific process.  
Some process cannot handle HTTP request, such as master process or [tengine Proc process](https://github.com/alibaba/tengine/blob/master/docs/modules/ngx_procs_module.md).  
The following example shows how to get information of master process.

```
$ gdb -q -x debug_pool.gdb -p <pid of master process>
(gdb) debug_pool
size:      191016 num:           4 cnum:           1 lnum:          20 ngx_init_cycle:13
size:           0 num:           1 cnum:           0 lnum:           0 main:403
size:           0 num:           2 cnum:           0 lnum:          12 ngx_http_server_names:751
size:      191016 num:           7 cnum:           1 lnum:          32 [SUMMARY]
```

get information of specific memory pool
---------------------------------------
The gdb script `debug_pool.gdb` provides another function to get information of specific memory pool.  
The following example shows memory usage of `ngx_cycle->pool`, which is used for parsing nginx configuration.

```
$ gdb -q -x debug_pool.gdb -p <pid of nginx process>
(gdb) pool_size ngx_cycle->pool
allocated from pool:                    163840 bytes
allocated via ngx_palloc_large():        27176 bytes
total size:                             191016 bytes
```

Data
====

Every line except the last one of output content has the same format, as follows:

"__size__: %12u __num__: %12u __cnum__: %12u __lnum__: %12u __\<function name\>__"

* __size__: size of current used memory of this pool
* __num__:  number of created pool (including current used pool and destroyed pool)
* __cnum__: number of current used pool
* __lnum__: number of calling ngx_palloc_large()
  * If allocated memory is larger than predefined size of memory pool, nginx will allocate memory via malloc(ngx_alloc) in ngx_palloc_large().
* __funcion name__: which nginx C function creates this pool
  * With function name of pool creator, we can know memory usage of every module, for example:
  * pool created by `ngx_http_create_request` is used for one HTTP request.
    * Because most modules allocates memory from this pool directly, it's hard to distinguish between them.
  * pool created by `ngx_event_accept` is used for TCP connection from client.
  * pool created by `ngx_http_upstream_connect` is used for HTTP connection to upstream peer.
  * pool created by `ngx_http_spdy_init` is used for SPDY session.
    * This pool will be freed and recreated by `ngx_http_spdy_keepalive_handler` when spdy connection goes idle.
  * pool created by `ngx_init_cycle` is used for parsing nginx configuration and keeping other global data structures.
  * pool created by `ngx_http_lua_init_worker` is used for conf.temp_pool of directive [init_worker_by_lua](https://github.com/openresty/lua-nginx-module#init_worker_by_lua).
  * ...

Last line of output content summarizes the information of all memory pools.

Nginx Compatibility
===================

The latest module is compatible with the following versions of nginx:

* 1.8.0 (stable version of 1.8.x)
* 1.6.3 (stable version of 1.6.x)
* 1.4.7 (stable version of 1.4.x)
* 1.2.9 (stable version of 1.2.x)

Tengine Compatibility
=====================

This module has been merged into tengine, see this [pull request](https://github.com/alibaba/tengine/pull/638).

Install
=======

Install this module from source:

```
$ wget http://nginx.org/download/nginx-1.8.0.tar.gz
$ tar -xzvf nginx-1.8.0.tar.gz
$ cd nginx-1.8.0/
$ patch -p1 < /path/to/ngx_debug_pool/debug_pool.patch
$ ./configure --add-module=/path/to/ngx_debug_pool
$ make && make install
```

Note that `debug_pool.patch` includes memory tracking logic in macro NGX_DEBUG_POOL, and [config](config) will enable this macro automatically.

Directive
=========

Syntax: **debug_pool**

Default: `none`

Context: `server, location`

The information of nginx memory pool usage will be accessible from the surrounding location.

Exception
=========

Memory allocated without using memory pool does not get taken into account with this module.  
For example,
* [ngx_http_spdy_module](http://nginx.org/en/docs/http/ngx_http_spdy_module.html) allocates a temporary buffer via malloc(ngx_alloc) for raw data of SYN_REPLY frame. After being compressed, this buffer will be freed immediately.
* All lua internal objects of Lua/LuaJIT used by [lua-nginx-module](https://github.com/openresty/lua-nginx-module) are allocated/freed via malloc/free. So the information of Lua/LuaJIT memory usage cannot be accessed from this module. 
