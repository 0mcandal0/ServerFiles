>shell
cd /nsconfig/ssl
ls -l | grep 2022
exit
update SSL Certkey xyz.domain.com_2021 -cert xyz.domain.com_2022.pfx -key xyz.domain.com_2022.pfx -inform PFX -password XXXXXX

update ssl certkey swift.domain.com_2021 -cert swift.domain.com_2022.pfx -key swift.domain.com_2022.pfx -inform -password XXXXXX
sh certkey xyz.domain.com_2022
save nsconfig
