Select-Xml -Path .\computer-elm.xml -XPath '/Computers/Computer/Name'| ForEach-Object { $_.Node.InnerXML }

Select-Xml -Path .\computer-elm.xml -XPath '/Computers/Computer'| ForEach-Object {$_.Node.name}   

Select-Xml -Path .\computer-elm.xml -XPath '/Computers/Computer'| ForEach-Object {$_.Node.InnerXml}

#Casting Xml as an Object
[xml]$xmlElm = Get-Content -Path .\computer-elm.xml
[xml]$xmlAttr = Get-Content -Path .\computer-elm.xml

##Reading Xml Element Object
$xmlElm.Computers.Computer.ip

##Reading Xml Attribute
$xmlElm.Computers.Computer.ip
$xmlAttr.Computers.Computer.ip

## iteration to XML Data

## casting the file text to an XML object
 [xml]$xmlAttr = Get-Content -Path .\computer-elm.xml

 ## looping through computers set with include="true"
 $xmlAttr.Computers.Computer | Where-Object include -eq 'true' |  ForEach-Object {
     ## see if the current computer is online
     if(Test-Connection -ComputerName $_.ip -Count 1 -Quiet)
     {
         $status = 'Connection OK'
     }
     else
     {
         $status = 'No Connection'
     }

     ## output the result object
     [pscustomobject]@{
         Name = $_.name
         Ip = $_.ip
         Status = $status
     }
 }
