#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use File::Copy;

my $BASEDIR    = `pwd`; chomp($BASEDIR);
my $SRCDIR     = "src";
my $CONFIGDIR  = "config";
my $OVERLAYDIR = "overlays";
my $IMAGEDIR   = "image";

if (! -d $SRCDIR)     { mkdir $SRCDIR; }
if (! -d $IMAGEDIR)   { mkdir $IMAGEDIR; }

# List of packages to build and include in image
my @packages;

my %kernel;
$kernel{package_type}   = "tarball";
$kernel{version}	= "3.12.29";
$kernel{basename}	= "linux-$kernel{version}";
$kernel{tarball}	= "$kernel{basename}.tar.gz";
$kernel{url}		= "http://www.kernel.org/pub/linux/kernel/v3.x/$kernel{tarball}";
push(@packages, \%kernel);

my %busybox;
$busybox{package_type}  = "tarball";
$busybox{version}	= "1.22.1";
$busybox{basename}	= "busybox-$busybox{version}";
$busybox{tarball}	= "$busybox{basename}.tar.bz2";
$busybox{url}		= "http://www.busybox.net/downloads/$busybox{tarball}";
push(@packages, \%busybox);

my %dropbear;
$dropbear{package_type} = "tarball";
$dropbear{version}	= "2014.63";
$dropbear{basename}	= "dropbear-$dropbear{version}";
$dropbear{tarball}	= "$dropbear{basename}.tar.bz2";
$dropbear{url}		= "http://matt.ucc.asn.au/dropbear/releases/$dropbear{tarball}";
push(@packages, \%dropbear);

my %libhugetlbfs;
$libhugetlbfs{package_type} = "tarball";
$libhugetlbfs{version}	= "2.17";
$libhugetlbfs{basename}	= "libhugetlbfs-$libhugetlbfs{version}";
$libhugetlbfs{tarball}	= "$libhugetlbfs{basename}.tar.gz";
$libhugetlbfs{url}	= "http://sourceforge.net/projects/libhugetlbfs/files/libhugetlbfs/$libhugetlbfs{version}/$libhugetlbfs{tarball}/download";
push(@packages, \%libhugetlbfs);

my %numactl;
$numactl{package_type}  = "tarball";
$numactl{version}	= "2.0.9";
$numactl{basename}	= "numactl-$numactl{version}";
$numactl{tarball}	= "$numactl{basename}.tar.gz";
$numactl{url}		= "ftp://oss.sgi.com/www/projects/libnuma/download/$numactl{tarball}";
push(@packages, \%numactl);

my %hwloc;
$hwloc{package_type}    = "tarball";
$hwloc{version}		= "1.8";
$hwloc{basename}	= "hwloc-$hwloc{version}";
$hwloc{tarball}		= "$hwloc{basename}.tar.gz";
$hwloc{url}		= "http://www.open-mpi.org/software/hwloc/v$hwloc{version}/downloads/$hwloc{tarball}";
push(@packages, \%hwloc);

my %ofed;
$ofed{package_type}	= "tarball";
$ofed{version}		= "3.12-1";
$ofed{basename}		= "OFED-$ofed{version}-rc2";
$ofed{tarball}		= "$ofed{basename}.tgz";
$ofed{url}		= "http://downloads.openfabrics.org/downloads/OFED/ofed-$ofed{version}/$ofed{tarball}";
push(@packages, \%ofed);

my %ompi;
$ompi{package_type}	= "tarball";
$ompi{version}		= "1.8.3";
$ompi{basename}		= "openmpi-$ompi{version}";
$ompi{tarball}		= "$ompi{basename}.tar.bz2";
$ompi{url}		= "http://www.open-mpi.org/software/ompi/v1.8/downloads//$ompi{tarball}";
push(@packages, \%ompi);

my %pisces;
$pisces{package_type}	= "git";
$pisces{basename}	= "pisces";
$pisces{src_subdir}	= "pisces";
$pisces{clone_cmd}[0]	= "git clone http://essex.cs.pitt.edu/git/pisces.git";
$pisces{clone_cmd}[1]	= "git clone http://essex.cs.pitt.edu/git/petlib.git";
$pisces{clone_cmd}[2]	= "git clone http://essex.cs.pitt.edu/git/xpmem.git";
$pisces{clone_cmd}[3]	= "git clone https://software.sandia.gov/git/kitten";
$pisces{clone_cmd}[4]	= "git clone http://essex.cs.pitt.edu/git/palacios.git";
push(@packages, \%pisces);

my %program_args = (
	build_kernel		=> 0,
	build_busybox		=> 0,
	build_dropbear		=> 0,
	build_libhugetlbfs	=> 0,
	build_numactl		=> 0,
	build_hwloc		=> 0,
	build_ofed		=> 0,
	build_ompi		=> 0,
	build_pisces		=> 0,

	build_image		=> 0,
	build_isoimage		=> 0,
	build_nvl_guest		=> 0
);

if ($#ARGV == -1) {
	usage();
	exit(1);
}

GetOptions(
	"help"			=> \&usage,
	"build-kernel"		=> sub { $program_args{'build_kernel'} = 1; },
	"build-busybox"		=> sub { $program_args{'build_busybox'} = 1; },
	"build-dropbear"	=> sub { $program_args{'build_dropbear'} = 1; },
	"build-libhugetlbfs"	=> sub { $program_args{'build_libhugetlbfs'} = 1; },
	"build-numactl"		=> sub { $program_args{'build_numactl'} = 1; },
	"build-hwloc"		=> sub { $program_args{'build_hwloc'} = 1; },
	"build-ofed"		=> sub { $program_args{'build_ofed'} = 1; },
	"build-ompi"		=> sub { $program_args{'build_ompi'} = 1; },
	"build-pisces"		=> sub { $program_args{'build_pisces'} = 1; },
	"build-image"		=> sub { $program_args{'build_image'} = 1; },
	"build-isoimage"        => sub { $program_args{'build_isoimage'} = 1; },
	"build-nvl-guest"	=> sub { $program_args{'build_nvl_guest'} = 1; },
	"<>"			=> sub { usage(); exit(1); }
);

sub usage {
	print <<"EOT";
Usage: build.pl [OPTIONS...]
EOT
}

# Scans given directory and copies over library dependancies 
sub copy_libs {
    my $directory = shift;
    my %library_list;

    foreach my $file (`find $directory -type f -exec file {} \\;`) {
        if ($file =~ /(\S+):/) {
            foreach my $ldd_file (`ldd $1 2> /dev/null \n`) {
                if ($ldd_file =~ /(\/\S+\/)(\S+\.so\S*) \(0x/) {
                    my $lib = "$1$2";
                    $library_list{$lib} = $1;
                    while (my $newfile = readlink($lib)) {
                        $lib =~ m/(.*)\/(.*)/;
                        my $dir = "$1";
                        if ($newfile =~ /^\//) {
                            $lib = $newfile;
                        }
                        else {
                            $lib = "$dir/$newfile";
                        }
                        $lib =~ m/(.*)\/(.*)/;
                        $library_list{"$1\/$2"} = $1;    # store in the library
                    }
                }
            }
        }
    }

    foreach my $file (sort keys %library_list) {
        # Do not copy libraries that will be nfs mounted
        next if $file =~ /^\/cluster_tools/;

        # Do not copy over libraries that already exist in the image
        next if -e "$directory/$file";

        # Create the target directory in the image, if necessary
        if (!-e "$directory/$library_list{$file}") {
            my $tmp = "$directory/$library_list{$file}";
            if ($tmp =~ s#(.*/)(.*)#$1#) {
                system("mkdir -p $tmp") == 0 or die "failed to create $tmp";
            }
        }

        # Copy library to the image
        system("rsync -a $file $directory/$library_list{$file}/") == 0
          or die "failed to copy list{$file}";
    }
}

# Download any missing package tarballs and repositories
for (my $i=0; $i < @packages; $i++) {
	my %pkg = %{$packages[$i]};
	if ($pkg{package_type} eq "tarball") {
		if (! -e "$SRCDIR/$pkg{tarball}") {
			print "CNL: Downloading $pkg{tarball}\n";
			system ("wget --directory-prefix=$SRCDIR $pkg{url} -O $SRCDIR\/$pkg{tarball}");
		}
	} elsif ($pkg{package_type} eq "git") {
		chdir "$SRCDIR" or die;
		if ($pkg{src_subdir}) {
			if (! -e "$pkg{src_subdir}") {
				mkdir $pkg{src_subdir} or die;
			}
			chdir $pkg{src_subdir} or die;
		}
		if (! -e "$pkg{basename}") {
			for (my $j=0; $j < @{$pkg{clone_cmd}}; $j++) {
				print "CNL: Running command '$pkg{clone_cmd}[$j]'\n";
				system ($pkg{clone_cmd}[$j]);
			}
		}
		chdir "$BASEDIR" or die;
	} else {
		die "Unknown package_type=$pkg{package_type}";
	}
}

# Unpack each downloaded tarball
for (my $i=0; $i < @packages; $i++) {
	my %pkg = %{$packages[$i]};
	next if $pkg{package_type} ne "tarball";

	if (! -d "$SRCDIR/$pkg{basename}") {
		print "CNL: Unpacking $pkg{tarball}\n";
		if ($pkg{tarball} =~ m/tar\.gz/) {
			system ("tar --directory $SRCDIR -zxvf $SRCDIR/$pkg{tarball}");
		} elsif ($pkg{tarball} =~ m/tar\.bz2/) {
			system ("tar --directory $SRCDIR -jxvf $SRCDIR/$pkg{tarball}");
		} elsif ($pkg{tarball} =~ m/tgz/) {
			system ("tar --directory $SRCDIR -zxvf $SRCDIR/$pkg{tarball}");
		} else {
			die "Unknown tarball type: $pkg{basename}";
		}
	}
}

# Build Linux Kernel
if ($program_args{build_kernel}) {
	print "CNL: Building Linux Kernel $kernel{basename}\n";
	chdir "$SRCDIR/$kernel{basename}" or die;
	if (-e ".config") {
		print "CNL: Aready configured, skipping copy of default .config\n";
	} else {
		print "CNL: Using default .config\n";
		copy "$BASEDIR/$CONFIGDIR/linux_config", ".config" or die;
		system "make oldconfig";
	}
	system "make -j 4 bzImage modules";
#	system "INSTALL_MOD_PATH=$BASEDIR/$SRCDIR/$kernel{basename}/_install/ make modules_install";
	system "sudo make modules_install";
	chdir "$BASEDIR" or die;
}

# Build Busybox
if ($program_args{build_busybox}) {
	print "CNL: Building Busybox $busybox{basename}\n";
	chdir "$SRCDIR/$busybox{basename}" or die;
	if (-e ".config") {
		print "CNL: Aready configured, skipping copy of default .config\n";
	} else {
		print "CNL: Using default .config\n";
		copy "$BASEDIR/$CONFIGDIR/busybox_config", ".config" or die;
		system "make oldconfig";
	}
	system "make";
	system "make install";
	chdir "$BASEDIR" or die;
}

# Build Dropbear
if ($program_args{build_dropbear}) {
	print "CNL: Building Dropbear $dropbear{basename}\n";
	chdir "$SRCDIR/$dropbear{basename}" or die;
	system "./configure --prefix=/";
	system "make PROGRAMS=\"dropbear dbclient dropbearkey dropbearconvert scp\" MULTI=1";
	chdir "$BASEDIR" or die;
}

# Build libhugetlbfs
if ($program_args{build_libhugetlbfs}) {
	print "CNL: Building libhugetlbfs $libhugetlbfs{basename}\n";
	chdir "$SRCDIR/$libhugetlbfs{basename}" or die;
	system "rm -rf ./_install";
	system "BUILDTYPE=NATIVEONLY make";
	system "BUILDTYPE=NATIVEONLY make install DESTDIR=$BASEDIR/$SRCDIR/$libhugetlbfs{basename}/_install";
	chdir "$BASEDIR" or die;
}

# Build numactl
if ($program_args{build_numactl}) {
	print "CNL: Building numactl $numactl{basename}\n";
	chdir "$SRCDIR/$numactl{basename}" or die;
	my $DESTDIR = "$BASEDIR/$SRCDIR/$numactl{basename}/_install/usr";
	$DESTDIR =~ s/\//\\\//g;
	system "sed '/^prefix/s/\\/usr/$DESTDIR/' Makefile > Makefile.cnl";
	system "mv Makefile Makefile.orig";
	system "cp Makefile.cnl Makefile";
	system "make";
	system "make install";
	system "mv Makefile.orig Makefile";
	system "rm -rf ./_install/share";  # don't need manpages
	chdir "$BASEDIR" or die;
}

# Build hwloc
if ($program_args{build_hwloc}) {
	print "CNL: Building hwloc $hwloc{basename}\n";
	chdir "$SRCDIR/$hwloc{basename}" or die;
	system "rm -rf ./_install";
	system "./configure --prefix=/usr";
	system "make";
	system "make install DESTDIR=$BASEDIR/$SRCDIR/$hwloc{basename}/_install";
	chdir "$BASEDIR" or die;
}

# Build OFED
if ($program_args{build_ofed}) {
	print "CNL: Building OFED $ofed{basename}\n";
	chdir "$SRCDIR/$ofed{basename}" or die;
	system "sudo ./install.pl --basic --without-depcheck --kernel-sources $BASEDIR/$SRCDIR/$kernel{basename} --kernel $kernel{version}";
	chdir "$BASEDIR" or die;
}

# Build OpenMPI
if ($program_args{build_ompi}) {
	print "CNL: Building OpenMPI $ompi{basename}\n";
	chdir "$SRCDIR/$ompi{basename}" or die;
	# This is a horrible hack. We're installing OpenMPI into /opt on the host.
	# This means we need to be root to do a make install and will possibly screw up the host.
	# We should really be using chroot or something better.
	system "LD_LIBRARY_PATH=$BASEDIR/$SRCDIR/slurm-install/lib ./configure --prefix=/opt/$ompi{basename} --disable-shared --enable-static --with-openib";
	system "make -j 2";
	system "sudo make install";
	chdir "$BASEDIR" or die;
}

# Build Pisces
if ($program_args{build_pisces}) {
	print "CNL: Building Pisces\n";

	# STEP 1: Configure and build Kitten... this will fail because
	# Palacios has not been built yet, but Palacios can't be built
	# until Kitten is configured in built. TODO: FIXME
	print "CNL: STEP 1: Building pisces/kitten stage 1\n";
	chdir "$SRCDIR/$pisces{src_subdir}/kitten" or die;
	if (-e ".config") {
		print "CNL: pisces/kitten aready configured, skipping copy of default .config\n";
	} else {
		print "CNL: pisces/kitten using default .config\n";
		copy "$BASEDIR/$CONFIGDIR/pisces/kitten_config", ".config" or die;
		system "make oldconfig";
	}
	system "make";
	chdir "$BASEDIR" or die;
	print "CNL: STEP 1: Done building pisces/kitten stage 1\n";

	# STEP 2: configure and build Palacios
	print "CNL: STEP 2: Building pisces/palacios\n";
	chdir "$SRCDIR/$pisces{src_subdir}/palacios" or die;
	if (-e ".config") {
		print "CNL: pisces/palacios aready configured, skipping copy of default .config\n";
	} else {
		print "CNL: pisces/palacios using default .config\n";
		copy "$BASEDIR/$CONFIGDIR/pisces/palacios_config", ".config" or die;
		system "make oldconfig";
	}
	system "make";
	chdir "$BASEDIR" or die;
	print "CNL: STEP 2: Done building pisces/palacios\n";

	# STEP 3: Rebuild Kitten... this will now succeed since Palacios has been built.
	print "CNL: STEP 3: Building pisces/kitten stage 2\n";
	chdir "$SRCDIR/$pisces{src_subdir}/kitten" or die;
	system "make";
	chdir "$BASEDIR" or die;
	print "CNL: STEP 3: Done building pisces/kitten stage 2\n";

	# STEP 4: Build petlib. Pisces depends on this.
	print "CNL: STEP 4: Building pisces/petlib\n";
	chdir "$SRCDIR/$pisces{src_subdir}/petlib" or die;
	system "make";
	chdir "$BASEDIR" or die;
	print "CNL: STEP 4: Done building pisces/petlib\n";

	# STEP 5: Build XPMEM for host Linux. Pisces depends on this.
	print "CNL: STEP 5: Building pisces/xpmem\n";
	chdir "$SRCDIR/$pisces{src_subdir}/xpmem/mod" or die;
	if (-e ".default_makefile_copied") {
		print "CNL: pisces/xpmem aready configured, skipping copy of default Makefile\n";
	} else {
		print "CNL: pisces/xpmem using default Makefile\n";
		copy "$BASEDIR/$CONFIGDIR/pisces/xpmem_makefile", "Makefile" or die;
		system "touch .default_makefile_copied";
	}
	system "PWD=$BASEDIR/$SRCDIR/$pisces{src_subdir}/xpmem/mod make";
	chdir "$BASEDIR" or die;
	print "CNL: STEP 5: Done building pisces/xpmem\n";

	# Step 6: Build Pisces
	print "CNL: STEP 6: Building pisces/pisces\n";
	chdir "$SRCDIR/$pisces{src_subdir}/pisces" or die;
	if (-e ".default_makefile_copied") {
		print "CNL: pisces/pisces aready configured, skipping copy of default Makefile\n";
	} else {
		print "CNL: pisces/pisces using default Makefile\n";
		copy "$BASEDIR/$CONFIGDIR/pisces/pisces_makefile", "Makefile" or die;
		system "touch .default_makefile_copied";
	}
	system "PWD=$BASEDIR/$SRCDIR/$pisces{src_subdir}/pisces make XPMEM=y";
	chdir "$BASEDIR" or die;
	print "CNL: STEP 6: Done building pisces/pisces\n";
}


##############################################################################
# Build Initramfs Image
##############################################################################
if ($program_args{build_image}) {
	#system "rm -rf $IMAGEDIR/*";

	# Create some directories needed for stuff
	system "mkdir -p $IMAGEDIR/etc";

	# Busybox
	system "cp -R $SRCDIR/$busybox{basename}/_install/* $IMAGEDIR/";
	system "ln -sf /bin/busybox $IMAGEDIR/bin/cut";
	system "ln -sf /bin/busybox $IMAGEDIR/bin/env";
	system "ln -sf /bin/gawk $IMAGEDIR/bin/awk";
	system "cp $IMAGEDIR/bin/busybox $IMAGEDIR/bin/busybox_root";
	system "ln -sf /bin/busybox_root $IMAGEDIR/bin/su";
	system "ln -sf /bin/busybox_root $IMAGEDIR/bin/ping";
	system "ln -sf /bin/busybox_root $IMAGEDIR/bin/ping6";
	system "ln -sf /bin/busybox_root $IMAGEDIR/usr/bin/traceroute";
	system "ln -sf /bin/busybox_root $IMAGEDIR/usr/bin/traceroute6";

	# Dropbear
	system "cp $SRCDIR/$dropbear{basename}/dropbearmulti $IMAGEDIR/bin";
	system "cp -R $CONFIGDIR/dropbear_files/etc/dropbear $IMAGEDIR/etc";
	chdir  "$BASEDIR/$IMAGEDIR/bin" or die;
	system "ln -s dropbearmulti dropbearconvert";
	system "ln -s dropbearmulti dropbearkey";
	# Use OpenSSH clients, rather than dropbear clients so that OpenSSH generated keys work.
	system "ln -s /usr/bin/scp scp";
	system "ln -s /usr/bin/ssh ssh";
	chdir  "$BASEDIR/$IMAGEDIR/sbin" or die;
	system "ln -s ../bin/dropbearmulti dropbear";
	chdir  "$BASEDIR/$IMAGEDIR/usr/bin" or die;
	system "ln -s ../../bin/dropbearmulti dbclient";
	chdir  "$BASEDIR" or die;

	# Use rsync to merge in skeleton overlay
	system("rsync -a $OVERLAYDIR/skel/\* $IMAGEDIR/") == 0
		or die "Failed to rsync skeleton directory to $IMAGEDIR";	

	# Instal linux kernel modules
	#system("rsync -a $SRCDIR/$kernel{basename}/_install/\* $IMAGEDIR/") == 0
	system("rsync -a /lib/modules/$kernel{version} $IMAGEDIR/lib/modules/") == 0
		or die "Failed to rsync linux modules to $IMAGEDIR";

	# Install numactl into image
	system("rsync -a $SRCDIR/$numactl{basename}/_install/\* $IMAGEDIR/") == 0
		or die "Failed to rsync numactl to $IMAGEDIR";

	# Install hwloc into image
	system("rsync -a $SRCDIR/$hwloc{basename}/_install/\* $IMAGEDIR/") == 0
		or die "Failed to rsync hwloc to $IMAGEDIR";

	# Install libhugetlbfs into image
	system("rsync -a $SRCDIR/$libhugetlbfs{basename}/_install/\* $IMAGEDIR/") == 0
		or die "Failed to rsync libhugetlbfs to $IMAGEDIR";

	# Install OpenMPI into image
	system("cp -R /opt/$ompi{basename} $IMAGEDIR/opt") == 0
		or die "Failed to rsync OpenMPI to $IMAGEDIR";

	# Install Pisces into image
	system "mkdir -p $IMAGEDIR/opt/pisces";
	system "mkdir -p $IMAGEDIR/opt/pisces_guest";
	system("cp $SRCDIR/pisces/xpmem/mod/xpmem.ko $IMAGEDIR/lib/modules") == 0
		or die "Failed to copy xpmem.ko to $IMAGEDIR/lib/modules";
	system("cp $SRCDIR/pisces/pisces/pisces.ko $IMAGEDIR/lib/modules") == 0
		or die "Failed to copy pisces.ko to $IMAGEDIR/lib/modules";
	system("rsync -a $SRCDIR/pisces/pisces/linux_usr/ $IMAGEDIR/opt/pisces") == 0
		or die "Failed to copy Pisces linux_usr to $IMAGEDIR/opt/pisces";
	system("cp $SRCDIR/pisces/kitten/vmlwk.bin $IMAGEDIR/opt/pisces_guest") == 0
		or die "Failed to copy Kitten vmlwk.bin to $IMAGEDIR/opt/pisces_guest";
	system("cp $SRCDIR/pisces/kitten/user/pisces/pisces $IMAGEDIR/opt/pisces_guest") == 0
		or die "Failed to copy Kitten pisces init_task to $IMAGEDIR/opt/pisces_guest";

	# Files copied from build host
	system "cp /etc/localtime $IMAGEDIR/etc";
	system "cp /lib64/libnss_files.so.* $IMAGEDIR/lib64";
	system "cp /usr/bin/ldd $IMAGEDIR/usr/bin";
	system "cp /usr/bin/strace $IMAGEDIR/usr/bin";
	system "cp /usr/bin/ssh $IMAGEDIR/usr/bin";
	system "cp /usr/bin/scp $IMAGEDIR/usr/bin";
	system "cp -R /usr/share/terminfo $IMAGEDIR/usr/share";

	# Infiniband files copied from build host
	system "cp -R /etc/libibverbs.d $IMAGEDIR/etc";
	system "cp /usr/lib64/libcxgb4-rdmav2.so $IMAGEDIR/usr/lib64";
	system "cp /usr/lib64/libocrdma-rdmav2.so $IMAGEDIR/usr/lib64";
	system "cp /usr/lib64/libcxgb3-rdmav2.so $IMAGEDIR/usr/lib64";
	system "cp /usr/lib64/libnes-rdmav2.so $IMAGEDIR/usr/lib64";
	system "cp /usr/lib64/libmthca-rdmav2.so $IMAGEDIR/usr/lib64";
	system "cp /usr/lib64/libmlx4-rdmav2.so $IMAGEDIR/usr/lib64";
	system "cp /usr/lib64/libmlx5-rdmav2.so $IMAGEDIR/usr/lib64";
	system "cp /usr/bin/ibv_devices $IMAGEDIR/usr/bin";
	system "cp /usr/bin/ibv_devinfo $IMAGEDIR/usr/bin";
	system "cp /usr/bin/ibv_rc_pingpong $IMAGEDIR/usr/bin";

	# Find and copy all shared library dependencies
	copy_libs($IMAGEDIR);

	# Build the guest initramfs image
	# Fixup permissions, need to copy everything to a tmp directory
	system "cp -R $IMAGEDIR $IMAGEDIR\_tmp";
	system "sudo chown -R root.root $IMAGEDIR\_tmp";
	system "sudo chmod +s $IMAGEDIR\_tmp/bin/busybox_root";
	system "sudo chmod 777 $IMAGEDIR\_tmp/tmp";
	system "sudo chmod +t $IMAGEDIR\_tmp/tmp";
	chdir  "$IMAGEDIR\_tmp" or die;
	system "sudo find . | sudo cpio -H newc -o > $BASEDIR/initramfs.cpio";
	chdir  "$BASEDIR" or die;
	system "cat initramfs.cpio | gzip > initramfs.gz";
	system "rm initramfs.cpio";
	system "sudo rm -rf $IMAGEDIR\_tmp";

	# As a convenience, copy Linux bzImage to top level
	system "cp $SRCDIR/$kernel{basename}/arch/x86/boot/bzImage bzImage";
}


##############################################################################
# Build an ISO Image
##############################################################################
if ($program_args{build_isoimage}) {
	system "mkdir -p isoimage";
	system "cp /usr/share/syslinux/isolinux.bin isoimage";
	system "cp $SRCDIR/$kernel{basename}/arch/x86/boot/bzImage isoimage";
	system "cp initramfs.gz isoimage/initrd.img";
	system "echo 'default bzImage initrd=initrd.img' > isoimage/isolinux.cfg";
#	system "echo 'default bzImage initrd=initrd.img console=hvc0' > isoimage/isolinux.cfg";
	system "mkisofs -J -r -o image.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table isoimage";
}


##############################################################################
# Build a Palacios Guest Image for the NVL (xml config file + isoimage)
##############################################################################
if ($program_args{build_nvl_guest}) {
        system "../../nvl/palacios/utils/guest_creator/build_vm config/nvl_guest.xml -o image.img"
}
