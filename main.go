package main

import (
	"log"
	"net"
	"net/url"
	"os"
	"os/exec"
	"strings"
)

const (
	registryBinary         = "/opt/drycc/registry/bin/registry"
	registryHtpasswd       = "/opt/drycc/registry/etc/htpasswd"
	registryConfigEnvVar   = "DRYCC_REGISTRY_CONFIG"
	registryRedirectEnvVar = "DRYCC_REGISTRY_REDIRECT"
	minioLookupEnvVar      = "DRYCC_MINIO_LOOKUP"
	minioBucketEnvVar      = "DRYCC_MINIO_BUCKET"
	minioEndpointEnvVar    = "DRYCC_MINIO_ENDPOINT"
	minioAccesskeyEnvVar   = "DRYCC_MINIO_ACCESSKEY"
	minioSecretkeyEnvVar   = "DRYCC_MINIO_SECRETKEY"
	defaultCommand         = "serve"
)

func main() {
	log.Println("INFO: Starting registry...")
	os.Setenv("REGISTRY_STORAGE", "s3")
	mEndpoint := os.Getenv(minioEndpointEnvVar)
	os.Setenv("REGISTRY_STORAGE_S3_REGIONENDPOINT", mEndpoint)

	region := "us-east-1" //region is required in distribution
	if endpointURL, err := url.Parse(mEndpoint); err == nil {
		if endpointURL.Hostname() != "" && net.ParseIP(endpointURL.Hostname()) == nil {
			region = strings.Split(endpointURL.Hostname(), ".")[0]
		}
	}
	os.Setenv("REGISTRY_STORAGE_S3_REGION", region)

	os.Setenv("REGISTRY_STORAGE_S3_ACCESSKEY", os.Getenv(minioAccesskeyEnvVar))
	os.Setenv("REGISTRY_STORAGE_S3_SECRETKEY", os.Getenv(minioSecretkeyEnvVar))
	os.Setenv("REGISTRY_STORAGE_S3_BUCKET", os.Getenv(minioBucketEnvVar))
	os.Setenv("REGISTRY_STORAGE_S3_ROOTDIRECTORY", "/registry")

	if os.Getenv(minioLookupEnvVar) == "path" {
		os.Setenv("REGISTRY_STORAGE_S3_FORCEPATHSTYLE", "true")
	}

	if os.Getenv(registryRedirectEnvVar) == "true" {
		os.Setenv("REGISTRY_STORAGE_REDIRECT_DISABLE", "false")
	} else {
		os.Setenv("REGISTRY_STORAGE_REDIRECT_DISABLE", "true")
	}

	// run /bin/init_registry
	os.Setenv("REGISTRY_AUTH", "htpasswd")
	os.Setenv("REGISTRY_AUTH_HTPASSWD_REALM", "basic-realm")
	os.Setenv("REGISTRY_AUTH_HTPASSWD_PATH", registryHtpasswd)
	cmd := exec.Command("/bin/init_registry")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatal("Error creating the registry bucket: ", err)
	}
	if len(os.Args) > 1 {
		cmd = exec.Command(registryBinary, os.Args[1:]...)
	} else {
		cmd = exec.Command(registryBinary, defaultCommand, os.Getenv(registryConfigEnvVar))
	}

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatal("Error starting the registry: ", err)
	}
	log.Println("INFO: registry started.")
}
