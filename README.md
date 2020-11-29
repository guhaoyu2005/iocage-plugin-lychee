# TrueNAS/FreeNAS/FreeBSD ```iocage``` Lychee Plugin.

An iocage installation script for [Lychee: A great looking and easy-to-use photo-management-system.](https://lycheeorg.github.io) [src](https://github.com/LycheeOrg/Lychee).


## Installation Instructions.

```
curl -o /tmp/lychee.json https://raw.githubusercontent.com/guhaoyu2005/iocage-plugin-lychee/master/lychee.json
iocage fetch -P /tmp/lychee.json -n lychee ip4_addr="igb0|10.0.0.1"
```

# Acknowledgments

[This script follows Lychee's official installation guide.](https://lycheeorg.github.io/docs/installation.html)

[Iocage script guide](https://www.ixsystems.com/documentation/freenas/11.3-U5/plugins.html#create-a-plugin)
