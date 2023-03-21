{ config, pkgs, lib, ... }:

# packageOverrides = pkgs: {
      # steam = pkgs.steam.override {
        # extraPkgs = pkgs: with pkgs; [
          # xorg.xhost
          # xorg.libXcursor
          # xorg.libXi
          # xorg.libXinerama
          # xorg.libXScrnSaver
          # curl
          # imagemagick
          # libpng
          # libpulseaudio
          # libvorbis
          # stdenv.cc.cc.lib
          # libkrb5
          # keyutils
          # libgdiplus
          # glxinfo
          # mesa-demos
          # vulkan-tools
          # vulkan-headers
          # vulkan-caps-viewer
          # vulkan-validation-layers
          # vulkan-extension-layer
          # vulkan-loader
          # vkBasalt
          # mangohud
          # gamescope
          # steamtinkerlaunch
        # ];
      # };
    # };

{
  imports = [ 
    #TODO flake.nix
    ./hardware-configuration.nix 
    ./services/flatpak.nix # fix fonts/icons issues in flatpak apps
    ./services/fonts.nix
    ./containers/minecraft.nix
    ./services/jellyfin.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ]; 
    };
  };
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; [ zenpower vendor-reset ];
    kernelParams = [
      # "ip=192.168.1.50:::::enp7s0:dhcp"
      "video=DP-1:2560x1440@120"
      "video=DP-2:2560x1440@120"
    ];

    initrd = {
      network = {
        enable = true;
      };
      services.swraid.mdadmConf = config.environment.etc."mdadm.conf".text;
      # secrets = {  }; TODO
      luks = {
        yubikeySupport = true;
        # fido2Support = true;
        reusePassphrases = true;
        mitigateDMAAttacks = true;
        devices = {
          "redpilled" = {
            device = "/dev/md0";
            preLVM = true;
            allowDiscards = true;
            bypassWorkqueues = true;
            yubikey = {
              slot = 2;
              twoFactor = true;
              gracePeriod = 30;
              keyLength = 64;
              saltLength = 64;
              storage = {
                device = "/dev/nvme0n1p1";
                fsType = "vfat";
                path = "/crypt-storage/default";
              };
            };
          };
        };
      };
    };

    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      generationsDir = {
        copyKernels = true;
      };
      # initScript = { enable = true; };
      systemd-boot = {
        enable = true;
        consoleMode = "keep";
	netbootxyz.enable = true;
	memtest86.enable = true; # TODO
        configurationLimit = 30;
      };

      timeout = 30;
    };
  };
  console = {
    earlySetup = false;
    keyMap = "us";
    # font = "Lat2-Terminus16";
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u32b.psf.gz";
  };

  hardware = {
    cpu.amd = { 
      updateMicrocode = true;
    };
    nvidia = { 
      modesetting.enable = true;
      powerManagement.enable = true;
    };
    firmware = with pkgs; [ 
      linux-firmware 
    ];
    bluetooth = { 
      enable = true; 
    };
    pulseaudio = { enable = false; };
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = [
        # AMD
        pkgs.rocm-opencl-icd
        pkgs.rocm-opencl-runtime
	
	# VAAPI
	pkgs.nvidia-vaapi-driver
	pkgs.libva
	pkgs.vaapiVdpau
	pkgs.libvdpau-va-gl
      ];
      extraPackages32 = [
	# VAAPI
	pkgs.driversi686Linux.vaapiVdpau
	pkgs.driversi686Linux.libvdpau-va-gl
      ];
    };
    opentabletdriver = {
      enable = true;
      daemon.enable = true;
    };
    steam-hardware.enable = true;
  };
  sound = { 
    enable = true;
    mediaKeys = {
      enable = true;
      volumeStep = "5%";
    };
  };
  zramSwap = { enable = true; algorithm = "zstd"; };
  
  security = {
    wrappers = {
      doas = {
        setuid = true;
        owner = "root";
        group = "root";
        source = "${pkgs.doas}/bin/doas";
      };
    };
    sudo = {
      enable = true;
      wheelNeedsPassword = true;
      # Todo
    };
    # Maybe migrate to doas
    doas = {
      enable = true;
      wheelNeedsPassword = true;
    };
    polkit = {
      enable = true;
      adminIdentities = [
        "unix-group:wheel"
        "unix-user:ashuramaru"
        "unix-user:meanrin"
      ];
      # Todo
      # extraConfig = '' '';
    };
    pam = {
      yubico = {
        enable = true;
        id = "20693163";
        mode = "client"; # TODO
        control = "sufficient"; # TODO
      };
      # ussh TODO
      # services = {  }; TODO
    };
    rtkit.enable = true;
  };

  networking = {  
    hostName = "unsisgend-int32";
    vlans = {
      eth0 = {
        id = 1;
	interface = "enp7s0";
      };
      # TODO
      # hosts = { };
    };
    nat = {
      enable = true;
      enableIPv6 = true;
      internalInterfaces = [ "ve-minecraft" ];
      externalInterface = "eth0";
    };
    networkmanager = {
      enable = true;
      dhcp = "internal";
      dns = "dnsmasq";
      ethernet.macAddress = "preserve";
      firewallBackend = "nftables";
      unmanaged = [ "interface-name:ve-*" ];
    };
    firewall = {
      enable = true;
      allowPing = true;
      allowedUDPPorts = [ 53 ];
      allowedTCPPorts = [ 53 80 443 ];
    };
  };
 
  services = {
    hardware = {
      bolt.enable = true;
      openrgb = {
        enable = true;
        motherboard = "amd";
      };
    };
    udev = {
      # TODO
      packages = with pkgs; [ 
        gnome.gnome-settings-daemon 
	gnome2.GConf
	opentabletdriver
      ];
      extraRules = ''
      # XP-Pen CT1060
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28bd", ATTRS{idProduct}=="0932", MODE="0666"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="28bd", ATTRS{idProduct}=="0932", MODE="0666"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28bd", ATTRS{idProduct}=="5201", MODE="0666"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="28bd", ATTRS{idProduct}=="5201", MODE="0666"
        SUBSYSTEM=="input", ATTRS{idVendor}=="28bd", ATTRS{idProduct}=="5201", ENV{LIBINPUT_IGNORE_DEVICE}="1"=
    '';
    };
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      layout = "us";
      xkbModel = "evdev";
      displayManager.gdm = { 
        enable = true;
	autoSuspend = false;
      };
      desktopManager.gnome.enable = true;
      libinput.enable = true; 
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      # TODO
    };
    openssh = {
      enable = true;
      settings = {
        UseDns = true;
        passwordAuthentication = false;
        kbdInteractiveAuthentication = true; 
        permitRootLogin = "prohibit-password";
      }; 
      ports = [ 22 52755 ];
      listenAddresses = [
        {
	  addr = "192.168.1.100";
	  port = 22;
	}
	{
	  addr = "0.0.0.0";
	  port = 52755;
	}
      ];
      banner = 
      ''
      ${pkgs.figlet}/bin/figlet -ctf slant "GAY SEX" | ${pkgs.lolcat}/bin/lolcat
      '';
      openFirewall = true;
      allowSFTP = true;
    };
    gnome = {
      sushi.enable = true;
      glib-networking.enable = true;
      tracker.enable = true;
      tracker-miners.enable = true;
      gnome-keyring.enable = true;
      at-spi2-core.enable = true;
      core-developer-tools.enable = true;
      core-utilities.enable = true;
      gnome-settings-daemon.enable = true;
      gnome-online-accounts.enable = true;
      gnome-online-miners.enable = lib.mkDefault false;
    };
    printing = { 
      enable = true;
    };
    fstrim = {
      enable = true;
      interval = "weekly";
    };
    pcscd.enable = true;
    flatpak.enable = true;
    gvfs.enable = true;
    # fwupd.enable = true; # todo
  };

  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      # TODO settings = {  };
    };
    # extraPortals = [
      # pkgs.xdg-desktop-portal-gtk
      # pkgs.xdg-desktop-portal-gnome
    # ];
  };

  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "qt5ct-style";
  };

  programs = {
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
    htop = {
      enable = true;
      package = pkgs.htop-vim;
      settings = {
        hide_kernel_threads = true;
        hide_userland_threads = true;
      };
    };
    git = {
      enable = true;
      lfs.enable = true;
      config = {
        init = { 
	  defaultBranch = "main";
        };
	url = {
	  "https://github.com/" = {
	  insteadOf = [ "gh:" "github:" ];
          };
        };
      };
    };
    gnupg.agent = {
      enable = true;
      pinentryFlavor = "curses";
      enableSSHSupport = true;
    };
    steam = {
      enable = true;
    };
    dconf.enable = true;
  };

  users = {
    mutableUsers = false;
    motdFile = "/etc/motd.d";
    groups = { 
      ashuramaru.gid = config.users.users.ashuramaru.uid;
      meanrin.gid = config.users.users.meanrin.uid;

      shared = {
        gid = 911;
        members = [ "ashuramaru" "meanrin" ];
      };
      jellyfin = {
        members = [ "ashuramaru" "meanrin" "shared" "video" "audio" ];
      };
      virt = {
	members = [ "docker" "podman" "libvirtd" "kvm" "qemu" ];
      }; 
    };
    users = {
      ashuramaru = {
        isNormalUser = true;
        description = "Marisa";
        home = "/home/ashuramaru";
        uid = 1000;
        initialHashedPassword = 
        "$6$79Eopfg.bX9kzgyR$mPzq3.dFGkCaX2NiAPiTqltBQ0b9gLpEPsX7YdKLyuMbvLssUlfFDiOhZ.FZ.AwS6JbXQ6AXB41Yq5QpJxWJ6/";
        hashedPassword = 
        "$6$9BY1nlAvCe/S63yL$yoKImQ99aC8l.CBPqGGrr74mQPPGucug13efoGbBaF.LT9GNUYeOk8ZejZpJhnJjPRkaU0hJTYtplI1rkxVnY.";
        extraGroups = [ "ashuramaru" "wheel" "networkmanager" "video" "audio" "virt" ];
        # openssh.authorizedKeys.keyFiles = [ "/etc/nixos/ssh/auth_ashuramaru" ];
      };
      meanrin = {
        isNormalUser = true;
        description = "Alex";
        home = "/home/meanrin";
        uid = 1001;
        initialHashedPassword = 
        "$6$Vyk8fqJUAWcfHcZ.$JrE0aK4.LSzpDlXNIHs9LFHyoaMXHFe9S0B66Kx8Wv0nVCnh7ACeeiTIkX95YjGoH0R8DavzSS/aSizJH1YgV0";
        extraGroups = [ "meanrin" "wheel" "networkmanager" "video" "audio" "virt" ];
	# openssh.authorizedKeys.keyFiles = [ "/root/" ];
      };
    };
  };

  systemd = {
    tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.hip}"
    ];
  };

  environment = {
    systemPackages = with pkgs; [

      # dev env
      gnumake
      gcc
      autoconf
      binutils
      gperf
      procps
      zlib
      m4

      # Essentials
      curl
      wget
      unzip
      unrar
      lz4
      
      # Utils
      util-linux
      neofetch
      nvtop
      zenith-nvidia
      # config.programs.htop see htop at
      pciutils
      usbutils
      nvme-cli
      fio # I/O tester
      lm_sensors
      libva-utils

      # CUDA (I FUCKING HATE THIS THING)
      cudatoolkit
      cudaPackages.cutensor

      # GNOME software and extensions
      gnome.gnome-tweaks
      gnome.gnome-themes-extra
      gnome.gnome-packagekit
      gnome.adwaita-icon-theme
      gnomeExtensions.appindicator

      # pkgs.firefox-wrapped 
      firefox
      
      # dev apps
      blender
      obs-studio

      # FFMPEG/ENC/DEC
      ffmpeg_5-full
      nv-codec-headers
      gst_all_1.gstreamer
      gst_all_1.gst-vaapi
      gst_all_1.gstreamermm
      gst_all_1.gst-devtools
      gst_all_1.gst-rtsp-server
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-base
      gst_all_1.gst-editing-services

    ];

    localBinInPath = true;
    sessionVariables = rec {
      XDG_CACHE_HOME = "\${HOME}/.cache";
      XDG_CONFIG_HOME = "\${HOME}/.config";
      XDG_DATA_HOME = "\${HOME}/.local/share";
      XDG_DATA_DIRS = [ 
        "${XDG_DATA_HOME}/.icons"
      ];
      CUDA_PATH="${pkgs.cudatoolkit}";
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      PATH = [
        # "${XDG_BIN_HOME}"
      ];
    };
    etc = {
      # TODO!!!!!!
      "mdadm.conf".text = ''
        HOMEHOST <ignore>
        ARRAY /dev/md0 metadata=1.2 UUID=2d0be890:bc0f45fb:96a52424:865c564f
      '';
    };
  };

  time.timeZone = "Europe/Kyiv";
  i18n = {
    defaultLocale = "en_US.utf8";
    supportedLocales = [ "all" ];
  };

  system.stateVersion = "23.05";
}