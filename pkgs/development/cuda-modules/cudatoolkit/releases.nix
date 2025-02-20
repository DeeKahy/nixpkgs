# Type Aliases
# CudaVersion = String (two-component version, e.g. "10.0")
# Release = {
#   version: String
#     - The version of CUDA.
#   url: String
#     - The URL to download the CUDA installer from.
#   sha256: String
#     - The SHA256 checksum of the CUDA installer.
# }
# Releases = AttrSet CudaVersion Release
{
  "12.8" = {
    version = "12.8.0";
    url = "https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda_12.8.0_570.86.10_linux.run";
    sha256 = "sha256-1y4m0qh886zjck3zd2jf2q4fqa6vp40iskwjqhv4wk6rsvf6f231";
  };
}
