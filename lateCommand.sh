# d-i late commands for Linux install

# Location for downloading preseed late command components
PRESEEDURL=http://puppet.ahc.ufl.edu/vabrrc
export SCRATCH=/root/tmp
mkdir -p $SCRATCH
export MYFILE=$SCRATCH/lateCommand.log

# Add the kernel option nomodeset to address problems with the nvidia hardware.  
# Make this change quietly.
sed -e 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/'  -i /etc/default/grub
sed -e 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="nomodeset"/'  -i /etc/default/grub
dpkg-reconfigure --frontend=noninteractive --unseen-only grub-pc
echo 'supersede domain-name "ahc.ufl.edu phhp.ufl.edu ctrip.ufl.edu shands.ufl.edu ufl.edu";' >> /etc/dhcp/dhclient.conf

# Adjust the name of this host
cd /sbin/
wget $PRESEEDURL/update-etc-hosts
chmod 755 /sbin/update-etc-hosts
/sbin/update-etc-hosts
# wait while the network restarts
sleep 5

# set a default puppet cron command
PUPPETCRONFILE=/etc/cron.d/puppetd
echo 'SHELL=/bin/sh' > $PUPPETCRONFILE
echo 'PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' >> $PUPPETCRONFILE
echo '@reboot root /bin/sleep 30 && /usr/sbin/puppetd --test --waitforcert 30 --server puppet.ahc.ufl.edu --pluginsync true' >> $PUPPETCRONFILE

# Get puppet key and cert for this node if they exist.
mkdir -p /root/.ssh
chmod 700 /root/.ssh
cd /root/.ssh/
wget $PRESEEDURL/ca.key  2>&1 >> $MYFILE
chmod 600 ca.key
cd /var/lib/puppet/
MYNAME=`hostname -f`
echo $MYNAME 2>&1 >> $MYFILE
scp -i /root/.ssh/ca.key  -o passwordauthentication=no -o StrictHostKeyChecking=no ca@puppet.ahc.ufl.edu:$MYNAME.tgz $SCRATCH/  2>&1 >> $MYFILE

# If we can find a saved key and cert for this node, use them. Puppetd should connect to the puppetmaster on the first boot.
if  [ -e $SCRATCH/$MYNAME.tgz ] ; then
  cd /var/lib/puppet/
  rm -rf *
  tar xzvf $SCRATCH/$MYNAME.tgz 2>&1 >> $MYFILE
  rm -f $SCRATCH/$MYNAME.tgz
fi
