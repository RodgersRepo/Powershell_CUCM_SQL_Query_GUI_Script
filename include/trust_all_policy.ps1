# Thanks to dstaudt for this. see
# https://github.com/CiscoDevNet/axl-powershell-samples/tree/main

$addDotNetCoreClassCertCheck = @"
 using System.Net;
 using System.Security.Cryptography.X509Certificates;
 public class TrustAllCertsPolicy:ICertificatePolicy {
    public bool CheckValidationResult (
        ServicePoint srvPoint,
        X509Certificate certificate,
        WebRequest request,
        int certificateProblem
    ){ return true; }
 }
"@

# Add the dotNet cert check above. Accepts unverifiable certs, like the potential
# security risk ahead browser warning you get with self signed certs. Instead of asking the user just accepts
# If you have a working PKI in your enterprise you probably wont need to include this. You will need
# to change any IP addresses for servers to FQDN. Check the scripts for this.
Add-Type -TypeDefinition $addDotNetCoreClassCertCheck
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy​