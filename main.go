package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
)

const (
	registryBinary  = "/opt/drycc/registry/bin/registry"
	registryConfig  = "/etc/docker/registry/config.yml"
	minioHostEnvVar = "DRYCC_MINIO_SERVICE_HOST"
	minioPortEnvVar = "DRYCC_MINIO_SERVICE_PORT"
	command         = "serve"
)

func main() {
	log.Println("INFO: Starting registry...")
	mHost := os.Getenv(minioHostEnvVar)
	mPort := os.Getenv(minioPortEnvVar)
	os.Setenv("REGISTRY_STORAGE", "s3")
	os.Setenv("REGISTRY_STORAGE_S3_BACKEND", "minio")
	os.Setenv("REGISTRY_STORAGE_S3_REGIONENDPOINT", fmt.Sprintf("http://%s:%s", mHost, mPort))

	if accesskey, err := ioutil.ReadFile("/var/run/secrets/drycc/objectstore/creds/accesskey"); err != nil {
		log.Fatal(err)
	} else {
		os.Setenv("REGISTRY_STORAGE_S3_ACCESSKEY", string(accesskey))
	}

	if secretkey, err := ioutil.ReadFile("/var/run/secrets/drycc/objectstore/creds/secretkey"); err != nil {
		log.Fatal(err)
	} else {
		os.Setenv("REGISTRY_STORAGE_S3_SECRETKEY", string(secretkey))
	}
	if bucket, err := ioutil.ReadFile("/var/run/secrets/drycc/objectstore/creds/registry-bucket"); err != nil {
		log.Fatal(err)
	} else {
		os.Setenv("REGISTRY_STORAGE_S3_BUCKET", string(bucket))
	}
	os.Setenv("REGISTRY_STORAGE_S3_REGION", "us-east-1")

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
