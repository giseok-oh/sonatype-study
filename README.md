# Sonatype Hands on Guide

> 본 문서는 Sonatype의 각 기능을 실습해보기 위해 제작된 가이드 문서입니다.
> 실습 시 License가 필요하며, License가 없을 경우 실습이 제한됩니다.

---

# 목차
- [1. 프로젝트 구성](#1-프로젝트-구성)
- [2. 소프트웨어 및 하드웨어 요구 사항](#2-소프트웨어-및-하드웨어-요구-사항)
- [3. 실습 환경 구축](#3-실습-환경-구축)

---

### 1. 프로젝트 구성

본 문서는 IQ Server 191 버전, Nexus Repository 3.80.0.06 버전 기준으로 작성되었으며, Webhook 기능을 연동해보기 위한 Node App과 LDAP 기능을 연동하기 위한 OpenLDAP이 포함되어 있습니다.

Nexus Repository는 실습을 위해 H2 Database를 사용합니다.

---

### 2. 소프트웨어 및 하드웨어 요구 사항

- **권장 하드웨어 요구 사항**
	- CPU: 8Core 16Thread 이상
	- RAM: 32GB 이상
	- Free Disk Space: 150GB 이상
- **최소 하드웨어 요구 사항**
	- CPU: 4Core 8Thread 이상
	- RAM: 16GB 이상
	- Free Disk Space: 150GB 이상
- **소프트웨어 요구 사항**
	- Host OS: Rocky Linux 8.10 이상
	- VirtualBox 7.1 버전 이상
	- Vagrant 2.4.6 버전 이상
	- Ansuble 2.16.3 버전 이상

---

### 3. 실습 환경 구축

```text
(2025.06.04) 실습 환경 구축은 Rocky Linux 8.10 버전을 기준으로 작성되었습니다.
```

1. **Host의 패키지를 업그레이드 하고, 필요한 패키지를 다운로드 받습니다.**
```bash
# 1. 패키지 업그레이드
sudo dnf upgrade -y

# 2. Python 업그레이드
sudo dnf install -y python312
sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
sudo alternatives --set python3 /usr/bin/python3.12

# 3. Vagrant 다운로드
sudo dnf install -y dnf-utils
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install -y vagrant

# 4. Ansible 다운로드
sudo dnf install -y ansible

# 5. Git 다운로드
sudo dnf install -y git

# 6. VirtualBox 다운로드(2025.06.04 기준 최신버전: 7.1.10)
sudo dnf install -y https://download.virtualbox.org/virtualbox/7.1.10/VirtualBox-7.1-7.1.10_169112_el8-1.x86_64.rpm
```
2. **프로젝트를 적절한 위치에 복제합니다.**
```bash
git clone /Path/Your/Project/
```
3. **프로젝트 디렉터리로 이동 후, 다음 명령을 수행합니다.**
```bash
# 프로젝트 디렉터리로 이동
cd /Path/Your/Project/

# 환경 구성 명령 실행
vagrant up
```
4. **IQ Server를 실행합니다.**
```bash
# 1. IQ Server VM 접속(password: vagrant)
ssh vagrant@192.168.56.10

# 2. IQ Server 관리용 계정으로 전환
sudo -u iqserver -i

# 3. IQ Server Directory로 이동
cd /opt/sonatype-iq-server

# 4. IQ Server 실행
# (방법 1) IQ Server Foreground 실행
# 라이선스 없이 처음 실행할 경우 Error가 발생하나, 다시 동일한 명령을 실행할 경우 정상적으로 실행됩니다.
java -jar nexus-iq-server-*.jar server config.yml 2> stderr.log

# (방법 2) IQ Server를 Service로 실행(systemd)
# 라이선스 없이 처음 실행할 경우 Error가 발생하나, 서비스를 재실행(restart) 할 경우 정상적으로 실행됩니다.
# 1. Service 등록용 스크립트 작성
sudo vi /opt/sonatype-iq-server/start.sh
...
#!/bin/bash
set -e
cd /opt/sonatype-iq-server/ || exit 1
JAR=$(ls nexus-iq-server-*.jar | head -n1)
exec java -jar "$JAR" server config.yml
...

# 2. Service  등록용 스크립트 권한 부여
sudo chmod +x /opt/sonatype-iq-server/start.sh

# 3. Service 파일 작성
sudo vi /etc/systemd/system/iqserver.service
...
[Unit]
Description=Sonatype IQ Server
After=network.target

[Service]
Type=simple
User=iqserver
ExecStart=/opt/sonatype-iq-server/start.sh
Restart=on-failure
StartLimitBurst=2
StartLimitInterval=600
StartLimitInterval=30
TimeoutSec=600

[Install]
WantedBy=multi-user.target
...

# 4. Service 실행 및 등록
sudo systemctl start iqserver
sudo systemctl enable --now iqserver

# 5. Service 상태 확인(IQ Server가 완전히 실행 되기까지 몇 분 정도 시간이 소요됩니다.)
sudo systemctl status iqserver

"
[접속 URL 및 초기 ID/Password]
URL: http://192.168.56.10:8070/
ID: admin
Password: admin123
"
```
5. **Slack Webhook Server를 실행합니다.**
```bash
# 1. Slack Webhook Server Directory로 이동
cd /opt/sonatype-webhook

# 2. Slack Webhook Server 파일 수정
vi app.js
...
const SLACK_WEBHOOK_URL = '/Your/Slack/Webhook/URL';
const SLACK_WEBHOOK_URL2 = '/Your/Slack/Webhook/URL';
...

# 3. Slack Webhook Server 실행
# 3-1. Foreground 실행/종료
node app.js
Ctrl + C

# 3-2. Backgroupd 실행/종료
pm2 start app.js
pm2 stop app.js
```
6. **LDAP 서버를 실행합니다.**
```bash
# 1. 서비스 등록 및 실행
sudo systemctl enable --noe slapd
sudo systemctl status slapd

# 2. home에 디렉토리 생성
mkdir -p ~/ldap

# 2. 관리자 패스워드 설정
slappasswd

# 3. DB 설정
sudo vi ~/ldap/db.ldif
...
dn: olcDatabase={2}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=osckorea,dc=com

dn: olcDatabase={2}mdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=admin,dc=osckorea,dc=com

dn: olcDatabase={2}mdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: <slappasswd>
...

# 4. DB 적용
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ~/ldap/db.ldif

# 5. 조직구조 생성
sudo vi ~/ldap/base.ldif
...
dn: dc=osckorea,dc=com
objectClass: top
objectClass: dcObject
objectClass: organization
o: OSC Korea
dc: osckorea

dn: cn=admin,dc=osckorea,dc=com
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: Directory Manager
userPassword: <slappasswd>
...

# 6. 조직구조 적용
sudo ldapadd -x -D cn=admin,dc=osckorea,dc=com -W -f ~/ldap/base.ldif

# 7. slapd 서비스 재실행
sudo systemctl restart slapd

# 8. 검색 테스트
sudo ldapsearch -x -LLL -b dc=osckorea,dc=com

# 9. 연결 테스트
sudo ldapsearch -x -H ldap://192.168.56.10 -b dc=osckorea,dc=com
```
7. **Nexus Repository Server를 실행합니다.**
```bash
# 1. Nexus Repository VM 접속(password: vagrant)
ssh vagrant@192.168.56.11

# 2. Nexus Repository 관리용 계정으로 전환
sudo -u nexus -i

# 3. Nexus Repository Directory로 이동
cd /opt/sonatype-nexus/nexus-*/bin

# 4. Nexus Repository 실행
# (방법 1) Nexus Repository Foreground 실행/종료
./nexus run
Ctrl + C

# (방법 2) Nexus Repository Background 실행/종료
./nexus start
./nexus stop

# 5. Nexus Repository 초기 관리자 비밀번호 조회
cat /opt/sonatype-nexus/sonatype-work/nexus3/admin.password

"
[접속 URL 및 초기 ID/Password]
URL: http://192.168.56.11:8081/
ID: admin
Password: admin.password 값
"
```

**최소 사양으로 변경하는 방법**
- 다음과 같이 Vagrantfile 내용을 수정하여 원하는 사양으로 변경하여 수행할 수 있습니다.(단, 다음과 같이 작성된 사양 밑으로 변경할 경우 실습 진행에 어려움이 있을 수 있습니다.)
```bash
vi Vagrantfile

"
Vagrantfile Example
  - cpus: 가상으로 할당된 cpu 코어 수 입니다.
  - memory: 가상머신에 할당된 Memory 용량입니다.
  - disksize: 가상머신의 디스크 용량입니다.
"
...
VM_LIST = {
  "iq" => {
    :ip => "192.168.56.10",
    :cpus => 1, # IQ Server 구성 시 Sonatype에서 권장하는 사양은 2cpus 입니다.
    :memory => 4_096, # IQ Server 구성 시 Sonatype에서 권장하는 사양은 8GB(8,192MB)입니다.
    :disksize => "64GB"
  },

  "nexus" => {
    :ip => "192.168.56.11",
    :cpus => 4, # H2 Database 기준 Sonatype에서 권장하는 사양은 8cpus 입니다.
    :memory => 8_192, # H2 Database 기준 Sonatype에서 권장하는 사양은 16GB(16,384MB)입니다.
    :disksize => "64GB" # H2 Database 기준 Sonatype에서 권장하는 사양은 500GB입니다.
  }
}
...
```

**환경 구성 중 오류가 발생했을 경우**
- 다음의 명령을 수행하여 환경 구성을 재시도 합니다.(네트워크 상태가 양호한 지 확인하세요.)
```bash
# 구성된 환경 전체 제거
vagrant destroy -f

# 환경 구성 명령 재실행
vagrant up
```
