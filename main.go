package main

import (
	"io/ioutil"
	"log"
	"net"
	"net/url"
	"os"
	"os/exec"
	"strings"
)

const (
	registryBinary      = "/opt/drycc/registry/bin/registry"
	registryConfig      = "/etc/docker/registry/config.yml"
	minioEndpointEnvVar = "DRYCC_MINIO_ENDPOINT"
	command             = "serve"
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

	if accesskey, err := ioutil.ReadFile("/var/run/secrets/drycc/minio/creds/accesskey"); err != nil {
		log.Fatal(err)
	} else {
		os.Setenv("REGISTRY_STORAGE_S3_ACCESSKEY", string(accesskey))
	}

	if secretkey, err := ioutil.ReadFile("/var/run/secrets/drycc/minio/creds/secretkey"); err != nil {
		log.Fatal(err)
	} else {
		os.Setenv("REGISTRY_STORAGE_S3_SECRETKEY", string(secretkey))
	}

	bucketNameFile := "/var/run/secrets/drycc/minio/creds/registry-bucket"
	if _, err := os.Stat(bucketNameFile); os.IsNotExist(err) {
		if bucket, err := ioutil.ReadFile(bucketNameFile); err != nil {
			log.Fatal(err)
		} else {
			os.Setenv("REGISTRY_STORAGE_S3_BUCKET", string(bucket))
		}
	} else {
		os.Setenv("REGISTRY_STORAGE_S3_BUCKET", "registry") // default bucket
	}

	// run /bin/create_bucket
	cmd := exec.Command("/bin/create_bucket")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatal("Error creating the registry bucket: ", err)
	}

	cmd = exec.Command(registryBinary, command, registryConfig)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatal("Error starting the registry: ", err)
	}
	log.Println("INFO: registry started.")
}

func getenv(name, dfault string) string {
	value := os.Getenv(name)
	if value == "" {
		value = dfault
	}
	return value
}
