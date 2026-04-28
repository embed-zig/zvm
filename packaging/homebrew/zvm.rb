class Zvm < Formula
  desc "Zig Version Manager"
  homepage "https://github.com/embed-zig/zvm"
  license "MIT"
  head "https://github.com/embed-zig/zvm.git", branch: "main"

  depends_on "zig" => :build

  def install
    system "zig", "build", "-Doptimize=ReleaseSafe", "--prefix", prefix
  end

  test do
    assert_match "zvm", shell_output("#{bin}/zvm --version")
  end
end
