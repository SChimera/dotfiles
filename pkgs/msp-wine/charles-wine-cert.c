#include <windows.h>
#include <wincrypt.h>
#include <stdio.h>
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *f = fopen(argv[1], "rb");
    unsigned char data[16384];
    if (!f) return 3;
    size_t len = fread(data, 1, sizeof(data), f);
    fclose(f);
    HCERTSTORE store = CertOpenStore(CERT_STORE_PROV_SYSTEM_A, 0, 0, CERT_SYSTEM_STORE_CURRENT_USER, "ROOT");
    if (!store) { printf("Open failed: %lu\n", (unsigned long)GetLastError()); return 4; }
    PCCERT_CONTEXT cert = NULL;
    if (!CertAddEncodedCertificateToStore(store, X509_ASN_ENCODING, data, len, CERT_STORE_ADD_USE_EXISTING, &cert)) {
        printf("Import failed: %lu\n", (unsigned long)GetLastError()); return 5;
    }
    PCCERT_CONTEXT found = CertFindCertificateInStore(store, X509_ASN_ENCODING, 0, CERT_FIND_EXISTING, cert, NULL);
    printf("Charles certificate in Wine current-user ROOT: %s\n", found ? "verified" : "NOT FOUND");
    if (found) CertFreeCertificateContext(found);
    CertFreeCertificateContext(cert);
    CertCloseStore(store, 0);
    return found ? 0 : 6;
}
