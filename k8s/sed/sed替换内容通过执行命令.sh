###
 # @Description: 
 # @version: 
 # @Author: zhu733756
 # @Date: 2020-09-15 14:08:10
 # @LastEditors: zhu733756
 # @LastEditTime: 2020-09-15 14:16:31
### 
sed -ri "s#tls.crt:\s?(.*)#tls\.crt: $(echo `cat domain/domain.crt.base64 | sed ":a;N;s/\n//g;ba"`)#" ./common/default-server-secret.yaml 
sed -ri "s#tls.key:\s?(.*)#tls\.key: $(echo `cat domain/domain.key.base64 | sed ":a;N;s/\n//g;ba"`)#" ./common/default-server-secret.yaml 