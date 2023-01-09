# update-static-Machine-catalog

open PowerShell on your DDC, and get the provisioning scheme name and the 
current snapshot that is being used for the master:
add-pssnapin *citrix* 
Get-ProvScheme 

This will return two very important things for each MCS machine catalog: 1) the 
ProvisioningSchemeName and 2) the MasterImageVM. You will notice that this contains the name of the 
Procedure to Update Static Catalog

If you pay close attention when you initially deploy the image, you will notice that MCS will do a full 
VMDK copy of your snapshot chain into a folder of every datastore that is defined in your hosted 
XenDesktop environment. This makes desktop creations extremely quick when scaling out additional 
VMs because it 1) negates the need to potentially copy VMDKs across datastores during desktop
creation and 2) negates the need to consolidate snapshots during creation. The folder will 
machine catalog name + basedisk + random datastore identifier assigned by XenDesktop. This 
applies to all MCS images; static and pooled.

We obviously want to keep the master of dedicated machines up-to-date to avoid unnecessary SCCM 
pushes, Windows updates, missed software, etc. when we deploy new desktops. 
does not give a GUI option for this, like we get on our pooled desktops in Studio:
the method of action when no GUI option is available? That is
There are two main things to consider here: the “Provisioning Scheme” and the new “Master Image.” 
The provisioning scheme name almost always matches the machine catalog name. It keeps track of the 
master image location and some other metadata. The master image is just the snapshot of your master 
machine that MCS does that full VMDK copy to each datastore that we talked about earlier.
Let’s get right to it. First, open PowerShell on your DDC, and get the provisioning scheme name and the 
t is being used for the master:

This will return two very important things for each MCS machine catalog: 1) the 
ProvisioningSchemeName and 2) the MasterImageVM. You will notice that this contains the name of the 
If you pay close attention when you initially deploy the image, you will notice that MCS will do a full 
n into a folder of every datastore that is defined in your hosted 
XenDesktop environment. This makes desktop creations extremely quick when scaling out additional 
VMs because it 1) negates the need to potentially copy VMDKs across datastores during desktop
creation and 2) negates the need to consolidate snapshots during creation. The folder will typically be 
identifier assigned by XenDesktop. This date to avoid unnecessary SCCM 
pushes, Windows updates, missed software, etc. when we deploy new desktops. Unfortunately, Citrix 
desktops in Studio:
That is right – PowerShell! 

There are two main things to consider here: the “Provisioning Scheme” and the new “Master Image.” 
The provisioning scheme name almost always matches the machine catalog name. It keeps track of the 
image is just the snapshot of your master 
machine that MCS does that full VMDK copy to each datastore that we talked about earlier.
Let’s get right to it. First, open PowerShell on your DDC, and get the provisioning scheme name and the 
ProvisioningSchemeName and 2) the MasterImageVM. You will notice that this contains the name of the 
snapshot that mirrors the name you provided in vSphere, followed by .snapshot. This makes it easy to 
locate! 

Let’s assume our current snapshot is named “v1” and our master is named “XDMaster1.” Therefore, the MasterImageVM should look like: 

XDHyp:\HostingUnits\<Cluster Name>\XDMaster1.vm\v1.snapshot 

Note: If your VM is in a resource pool, this path will also contain that as a “directory.” 
We will create a snapshot named “v2” on the master after making some changes, updates, etc. ( it is 
good to create snapshot before changes too for easy rollback but give proper name for easy 
identification) and shutdown the master. Let us verify that XenDesktop now sees this snapshot in our 
hypervisor environment: 

get-childitem -path “XDHyp:\HostingUnits\<Cluster Name>\XDMaster1.vm\v1.snapshot” 

You will see that v2.snapshot is now a child item of your v1.snapshot! Good deal! So how do we point 
MCS to this snapshot? Simple: 

First, let’s make it easy on ourselves and create a couple of variables. The two important ones that I 
touched on earlier: ProvisioningSchemeName and MasterImageVM: 

$ProvScheme = “Windows 10 Static” 

“Windows 10 Static” will be the ProvisioningSchemeName from earlier, or usually the name of your 
Machine Catalog. 
$NewMasterImage = “XDHyp:\HostingUnits\<Cluster 
Name>\XDMaster1.vm\v1.snapshot\v2.snapshot” 

That will be the full path to your new snapshot. Remember to use get-childitem to ensure that the DDC 
sees your new snapshot. 

Now, we will use the Publish-ProvMasterVMImage cmdlet to wrap it all up! 
Publish-ProvMasterVMImage -ProvisioningSchemeName $ProvScheme -MasterImageVM 
$NewMasterImage 

After running this command, pay attention to your vSphere tasks. You will see a temporary VM get 
copied, VMDKs get copied to the various datastores, and you should finally get a response from 
PowerShell that states 100% completion and where the new master image location points. 
If you see the dreadful red text, pay attention and make sure you got your paths correct. It is easy to 
mistype the XDHyp path, forget quotes, etc. 
Procedure to update Pooled Catalog 
Citrix recommends that you save copies or snapshots of master images before you update the machines 
in the catalog. The database keeps an historical record of the master images used with each Machine 
Catalog. You can roll back (revert) machines in a catalog to use the previous version of the master image 
if users encounter problems with updates you deployed to their desktops, thereby minimizing user 
downtime. Do not delete, move, or rename master images; otherwise, you will not be able to revert a 
catalog to use them. 
For catalogs that use Provisioning Services, you must publish a new vDisk to apply changes to the 
catalog. For details, see the Provisioning Services documentation. 
After a machine is updated, it restarts automatically. 
Update or create a new master image
Before you update the Machine Catalog, either update an existing master image or create a new one on 
your host hypervisor. 
1. On your hypervisor or cloud service provider, take a snapshot of the current VM and give the 
snapshot a meaningful name. This snapshot can be used to revert (roll back) machines in the 
catalog, if needed. 
2. If necessary, power on the master image, and log on. 
3. Install updates or make any required changes to the master image. 
4. If the master image uses a personal vDisk, update the inventory. 
5. Power off the VM. 
6. Take a snapshot of the VM, and give the snapshot a meaningful name that will be recognized 
when the catalog is updated in Studio. Although Studio can create a snapshot, Citrix 
recommends that you create a snapshot using the hypervisor management console, and then 
select that snapshot in Studio. This enables you to provide a meaningful name and description 
rather than an automatically generated name. For GPU master images, you can change the 
master image only through the XenServer XenCenter console. 
Update the catalog
To prepare and roll out the update to all machines in a catalog: 
1. Select Machine Catalogs in the Studio navigation pane. 
2. Select a catalog and then select Update Machines in the Actions pane. 
3. On the Master Image page, select the host and the image you want to roll out. 
4. On the Rollout Strategy page, choose when the machines in the Machine Catalog will be 
updated with the new master image: on the next shutdown or immediately. See below for 
details. 
5. Verify the information on the Summary page and then click Finish. Each machine restarts 
automatically after it is updated. 
Tip: If you are updating a catalog using the PowerShell SDK directly, rather than Studio, you can specify a 
hypervisor template (VMTemplates), as an alternative to an image or a snapshot of an image. 
Ref: 
