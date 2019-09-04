# docker-ovpn-xor
Easy OpenVPN server setup with docker.

## Setup
Make a copy of [docker-compose.yml](docker-compose.yml) and change the options however you want.
Next, run `docker-compose up -d`. Since this is the first time running the VPN server, it will
generate all the configs. Generating the configs can take a while, monitor the progress with
`docker-compose logs -f`. Finally, copy the client configs from `config/clients/` to your devices
and test it.

## Options

Pass extra arguments to the openvpn server by putting them in the command,
for example `command: ["--verb", "5"]` in the docker-compose file.

All other options are set as environment variables.
Options only affect config generation - once the configs have been created, the options do nothing.
Configs are generated the first time server runs.

- `NUM_CLIENT_CONFIGS`
    - The number of client VPN configs to generate.
    - Default: 25
- `SCRAMBLE`
    - Set to `1` to generate configs with `scramble xormask {random ascii character}`. Read about the [openvpn xor patch](https://tunnelblick.net/cOpenvpn_xorpatch.html).
    - Default: `0` (off)
- `PUBLIC_ADDRESS`
    - Public IP address of the server. This IP address will be put in the client configs.
    - Default: get IPv4 address from [ipify.org](https://www.ipify.org/)
- `PUBLIC_PORT`
    - The port that the server is accessible on from the public internet.
    This port will be put in the client configs.
    Note that the server will always listen on port 1194 inside the docker container.
    Change the port with docker port mappings.
    - Default: 1194
    
## Limitations

- Currently only supports TCP.
- Internally, the server uses a virtual network with IP addresses `10.232.0.0/24`.
If a client's network uses this range, weird things might happen.