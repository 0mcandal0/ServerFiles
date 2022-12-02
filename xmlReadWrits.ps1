$fileName = “employees.xml”;
$xmlDoc = [System.Xml.XmlDocument](Get-Content $fileName);

$newXmlEmployee = $xmlDoc.employees.AppendChild($xmlDoc.CreateElement("employee"));
$newXmlEmployee.SetAttribute("id","111");

$newXmlNameElement = $newXmlEmployee.AppendChild($xmlDoc.CreateElement("name"));
$newXmlNameTextNode = $newXmlNameElement.AppendChild($xmlDoc.CreateTextNode("Iain Brighton"));

$newXmlAgeElement = $newXmlEmployee.AppendChild($xmlDoc.CreateElement("age"));
$newXmlAgeTextNode = $newXmlAgeElement.AppendChild($xmlDoc.CreateTextNode("37"));

$xmlDoc.Save($fileName);
