class CodexRotate < Formula
  desc "Multi-account manager for Codex CLI with automatic rotation on rate limits"
  homepage "https://github.com/vaskoyudha/CodexCLI-Rotate"
  url "https://github.com/vaskoyudha/CodexCLI-Rotate/archive/refs/tags/v1.3.1.tar.gz"
  # sha256 will be updated after release
  # sha256 "PLACEHOLDER"
  license "MIT"

  depends_on "bash"
  depends_on "jq"
  depends_on "util-linux" # for flock

  def install
    bin.install "bin/codex-rotate"

    bash_completion.install "completions/codex-rotate.bash" => "codex-rotate"
    zsh_completion.install "completions/codex-rotate.zsh" => "_codex-rotate"
    fish_completion.install "completions/codex-rotate.fish"
  end

  test do
    assert_match "codex-rotate v", shell_output("#{bin}/codex-rotate help")
  end
end
