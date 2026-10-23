require core-image-autoware.bb

SUMMARY = "Autoware planning simulator demo on the AWSIM Shinjuku map"
DESCRIPTION = "${SUMMARY}. Contains a CC-BY-NC-4.0 map: not for production or commercial use."

IMAGE_INSTALL:append = " \
    packagegroup-autoware-devtools \
    autoware-planning-sim-demo \
"
