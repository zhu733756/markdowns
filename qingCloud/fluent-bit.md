```
 docker run -ti -v /var/log/audit:/audit fluent/fluent-bit:1.7  /fluent-bit/bin/fluent-bit -i tail  -p path=/audit/audit.log -o stdout 

```

```
 ./test.sh | fluent-bit -i stdin -o stdout
```
