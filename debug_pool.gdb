# MUST compile nginx with ngx_debug_pool module

# (gdb) debug_pool
define debug_pool
  set $_i = 0
  set $_ss = 0
  set $_ns = 0
  set $_cs = 0
  set $_ls = 0
  while $_i < 997
    set $_ps = ngx_pool_stats[$_i]
    while $_ps != 0x0
      printf "size:%12u num:%12u cnum:%12u lnum:%12u %s:%d\n", \
        $_ps->size, $_ps->num, $_ps->cnum, $_ps->lnum, $_ps->func, $_i
      set $_ss = $_ss + $_ps->size
      set $_ns = $_ns + $_ps->num
      set $_cs = $_cs + $_ps->cnum
      set $_ls = $_ls + $_ps->lnum
      set $_ps = $_ps->next
    end
    set $_i = $_i + 1
  end
  printf "size:%12u num:%12u cnum:%12u lnum:%12u [SUMMARY]\n", $_ss, $_ns, $_cs, $_ls
end

# (gdb) pool_size <pointer: ngx_pool_t *>
define pool_size
  set $_pool = (ngx_pool_t *) $arg0
  set $_ls = 0
  set $_l = $_pool->large
  while $_l != 0x0
    set $_ls = $_ls + $_l->size
    set $_l = $_l->next
  end
  printf "allocated from pool:              %12u bytes\n", $_pool->size
  printf "allocated via ngx_palloc_large(): %12u bytes\n", $_ls
  printf "total size:                       %12u bytes\n", $_pool->size + $_ls
end
