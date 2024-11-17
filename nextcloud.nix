{ self, config, lib, pkgs, ... }: {
# Based on https://carjorvaz.com/posts/the-holy-grail-nextcloud-setup-made-easy-by-nixos/
	networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 80 443 5487 ];
	nixpkgs.config.allowUnfree = true;
	security.acme = {
		acceptTerms = true;
		defaults = {
			email = "your email";
			dnsProvider = "cloudflare";
# location of your CLOUDFLARE_DNS_API_TOKEN=[value]
# https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#EnvironmentFile=
			environmentFile = "/a/file/path/acme-env";
		};
	};
	services = {
		resolved.enable = true;
		nginx = {
			defaultListen = [ { addr = "ipv4"; } { addr = "[ipv6]"; } ];
			virtualHosts = {
				"your_domain" = {
					forceSSL = true;
					enableACME = true;
					acmeRoot = null;
					locations = { 
						"/".proxyWebsockets = true;
# uh, equals what?
						"~ ^\/nextcloud\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+|.+\/richdocumentscode\/proxy)\.php(?:$|\/)" = {};
					};
				};
				"your_office_domain" = {
					forceSSL = true;
					enableACME = true;
					acmeRoot = null;
					locations = {
# static files
						"^~ /loleaflet" = {
							proxyPass = "http://localhost:9980";
							extraConfig = ''
								proxy_set_header Host $host;
							'';
						};
# WOPI discovery URL
						"^~ /hosting/discovery" = {
							proxyPass = "http://localhost:9980";
							extraConfig = ''
								proxy_set_header Host $host;
							'';
						};

# Capabilities
						"^~ /hosting/capabilities" = {
							proxyPass = "http://localhost:9980";
							extraConfig = ''
								proxy_set_header Host $host;
							'';
						};

# download, presentation, image upload and websocket
						"~ ^/lool" = {
							proxyPass = "http://localhost:9980";
							extraConfig = ''
								proxy_set_header Upgrade $http_upgrade;
							proxy_set_header Connection "Upgrade";
							proxy_set_header Host $host;
							proxy_read_timeout 36000s;
							'';
						};

# Admin Console websocket
						"^~ /lool/adminws" = {
							proxyPass = "http://localhost:9980";
							extraConfig = ''
								proxy_set_header Upgrade $http_upgrade;
							proxy_set_header Connection "Upgrade";
							proxy_set_header Host $host;
							proxy_read_timeout 36000s;
							'';
						};
					};
				};
			};
		};

		nextcloud = {
			enable = true;
			hostName = "your_domain";
# Need to manually increment with every major upgrade.
			package = pkgs.nextcloud28;
# Let NixOS install and configure the database automatically.
			database.createLocally = true;
# Let NixOS install and configure Redis caching automatically.
			configureRedis = true;
# Increase the maximum file upload size.
			maxUploadSize = "16G";
			https = true;
			autoUpdateApps.enable = true;
			extraAppsEnable = true;
			extraApps = with config.services.nextcloud.package.packages.apps; {
# List of apps we want to install and are already packaged in
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
				inherit bookmarks calendar contacts notes cookbook deck previewgenerator twofactor_webauthn memories;
			};
			config = {
				overwriteProtocol = "https";
				defaultPhoneRegion = "US";
				dbtype = "pgsql";
				adminuser = "admin";
				adminpassFile = "/your/file/path/nextcloud-admin-pass";
                                #maintenanceWindowStart = "6";
                                trustedProxies = [ "ipv4 addr of proxy" ];
			};
			appstoreEnable = true;
# Suggested by Nextcloud's health check.
			phpOptions."opcache.interned_strings_buffer" = "16";
		};
# Nightly database backups. It just puts the db in a file, maybe back that file up...
		postgresqlBackup = {
			#backup location /var/backup/postgresql
			enable = true;
			startAt = "*-*-* 01:15:00";
		};

	};
	virtualisation.oci-containers = {
		backend = "docker";
		containers.collabora = {
			image = "collabora/code";
			imageFile = pkgs.dockerTools.pullImage {
				imageName = "collabora/code";
				imageDigest = "sha256:aab41379baf5652832e9237fcc06a768096a5a7fccc66cf8bd4fdb06d2cbba7f";
				sha256 = "sha256-M66lynhzaOEFnE15Sy1N6lBbGDxwNw6ap+IUJAvoCLs=";
			};
			ports = ["9980:9980"];
			environment = {
				domain = "your_domain";
				extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
			};
			extraOptions = ["--cap-add" "MKNOD" "--net=host"];
		};
	};

				  }

