SSL Certificate
===============

We're currently using Thawte wildcard certificates for our
infrastructure. They have these two official documentations to follow:

* https://search.thawte.com/support/ssl-digital-certificates/index?page=content&actpl=CROSSLINK&id=SO17666
* https://search.thawte.com/support/ssl-digital-certificates/index?page=content&actp=CROSSLINK&id=SO25709

As we don't know if they will be available when you're reading it,
here is a quick and dirty tutorial.

## Installing the issued certificate

To be able to install the certificates you have to download a `zip`
file from Thawte website. Ask the responsible for buying the
certificate or the webmaster for the link.

After unzipping the `zip` file you will find `ssl_certificate.cer` and
`IntermediateCA.crt` files. These files must be concatenated into one
chain of certificates.

    cat ssl_certificate.cer IntermediateCA.cer >> intervac.crt

Please refer to nginx files under `infra` to locate the directory
where the certificate should be put in and `scp` this new file
(`intervac.crt`) the directory you found there:

    scp ssl_certificate.cer IntermediateCA.cer intervac:/dir/mentioned/on/infra/subfolder

Just to be sure everything is configured in a proper way, check if
`/etc/nginx/sites-enables/intervac` has `ssl on` and `ssl_certificate` and
`ssl_certificate_key` pointing to the correct files and directory (the
`/dir/mentioned/on/infra/subfolder`).

Restart nginx, wait for the application server to get up and running and it's
done for the app! :)

Be sure if the load balancer is configured to serve the SSL
certificate as well. At the moment (Apr 2018) we are using Linode's
Node balancer. Every time we change our certificate, we have to submit
it to the node balancer as well so it can create the TLS connection
from the client to the balancer.

When you change the load balancer and the app you're ready to go! 👍


## Reissue the certificate

In case you have to reissue the certificate, be prepared to wait for some days.
The first step is to generate a CSR (Certificate Signing Request):

    openssl req -new -newkey rsa:2048 -nodes -keyout intervac.key -out intervac.csr

It will ask some questions and here are the answers:

    Country Name (2 letter code) [AU]: NL
    State or Province Name (full name) [Some-State]: Gelderland
    Locality Name (eg, city) []: Oosterbeek
    Organization Name (eg, company) [Internet Widgits Pty Ltd]: Intervac I.H.E.S. B.V.
    Common Name (e.g. server FQDN or YOUR name) []: *.intervac-homeexchange.com

**Questions not mentioned here must reveive empty answers**.

This CSR will be tied to your private key (`intervac.key`), be sure to keep it
safe. After that, you will have to submit it to Thawte and they have they own
bureaucracy to be sure you are Intervac for sure (security reasons).

Thawte will validate some information with the contacts mentioned in our account
and then the process will continue as described on *Installing the issued
certificate*, except that you will not have to generate the *private key*, you
will just use the one you generated along with the CSR.
