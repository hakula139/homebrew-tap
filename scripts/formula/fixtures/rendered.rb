class ExampleTool < Formula
  url "https://github.com/hakula139/example-tool/releases/download/v1.2.3-rc.1/example-tool-x86_64-unknown-linux-gnu.tar.gz"
  version "1.2.3-rc.1"
  sha256 "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

  on_macos do
    url "https://github.com/hakula139/example-tool/releases/download/v1.2.3-rc.1/example-tool-aarch64-apple-darwin.tar.gz"
    sha256 "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  end

  def install
    bin.install "example"
  end
end
