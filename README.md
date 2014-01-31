SQLi
====

General Scripts to help with various types of SQL Injection

mysqli_boolean.rb => MySQL Boolean Blind Injection Assistant

mysqli_regexp.rb  => MySQL Regexp Conditional Error Based Injection Assistant

mymof => Windows MySQL Privileged User to SYSTEM MOF RCE Exploit
  - mymof.rb => The exploit script
  - /payloads/ => contains binary payloads for use with script (Netcat nc.exe & the Small Backdoor sbd.exe)

myudf => Windows MySQL Privileged User to SYSTEM User Defined Function (UDF) RCE Exploit
  - myudf.rb => The exploit script
  - /paylaods/ => UDF DLL Files to Inject based on target architecture type, also includes a C based source code file for which you can create your own reverse shell DLL payload to use with tool
