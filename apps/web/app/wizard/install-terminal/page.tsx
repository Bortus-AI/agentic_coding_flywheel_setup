"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ExternalLink, Terminal, Check } from "lucide-react";
import { Button, Card, CommandCard } from "@/components";
import { markStepComplete } from "@/lib/wizardSteps";
import { getUserOS, type OperatingSystem } from "@/lib/userPreferences";

function MacContent() {
  return (
    <div className="space-y-6">
      <div className="space-y-4">
        <p className="text-muted-foreground">
          Install <strong>Ghostty</strong> or <strong>WezTerm</strong> — either
          is a great choice. Open it once after installing to make sure it works.
        </p>

        <div className="grid gap-3 sm:grid-cols-2">
          <Card className="p-4">
            <a
              href="https://ghostty.org/download"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-between"
            >
              <div>
                <h3 className="font-semibold">Ghostty</h3>
                <p className="text-sm text-muted-foreground">
                  Fast, native terminal
                </p>
              </div>
              <ExternalLink className="h-4 w-4 text-muted-foreground" />
            </a>
          </Card>

          <Card className="p-4">
            <a
              href="https://wezfurlong.org/wezterm/installation.html"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-between"
            >
              <div>
                <h3 className="font-semibold">WezTerm</h3>
                <p className="text-sm text-muted-foreground">
                  GPU-accelerated terminal
                </p>
              </div>
              <ExternalLink className="h-4 w-4 text-muted-foreground" />
            </a>
          </Card>
        </div>
      </div>

      <div className="rounded-lg border border-green-200 bg-green-50 p-4 dark:border-green-900 dark:bg-green-950">
        <div className="flex items-start gap-3">
          <Check className="mt-0.5 h-5 w-5 text-green-600 dark:text-green-400" />
          <div>
            <p className="font-medium text-green-800 dark:text-green-200">
              SSH is already installed
            </p>
            <p className="text-sm text-green-700 dark:text-green-300">
              macOS includes SSH by default, so you&apos;re ready to connect to
              your VPS.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

function WindowsContent() {
  return (
    <div className="space-y-6">
      <div className="space-y-4">
        <p className="text-muted-foreground">
          Install <strong>Windows Terminal</strong> from the Microsoft Store.
          Open it once after installing.
        </p>

        <Card className="p-4">
          <a
            href="ms-windows-store://pdp/?ProductId=9N0DX20HK701"
            className="flex items-center justify-between"
          >
            <div>
              <h3 className="font-semibold">Windows Terminal</h3>
              <p className="text-sm text-muted-foreground">
                Microsoft Store (free)
              </p>
            </div>
            <ExternalLink className="h-4 w-4 text-muted-foreground" />
          </a>
        </Card>
      </div>

      <div className="space-y-3">
        <h3 className="font-medium">Verify SSH is available</h3>
        <p className="text-sm text-muted-foreground">
          Open Windows Terminal and run this command. You should see a version
          number.
        </p>
        <CommandCard
          command="ssh -V"
          description="Check SSH version"
          showCheckbox
          persistKey="verify-ssh-windows"
        />
      </div>
    </div>
  );
}

export default function InstallTerminalPage() {
  const router = useRouter();
  const [os, setOS] = useState<OperatingSystem | null>(null);
  const [isNavigating, setIsNavigating] = useState(false);

  useEffect(() => {
    const storedOS = getUserOS();
    if (storedOS) {
      setOS(storedOS);
    } else {
      // If no OS selected, redirect back to step 1
      router.push("/wizard/os-selection");
    }
  }, [router]);

  const handleContinue = useCallback(() => {
    markStepComplete(2);
    setIsNavigating(true);
    router.push("/wizard/generate-ssh-key");
  }, [router]);

  // Show loading state while detecting OS
  if (!os) {
    return (
      <div className="flex items-center justify-center py-12">
        <Terminal className="h-8 w-8 animate-pulse text-muted-foreground" />
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="space-y-2">
        <h1 className="text-3xl font-bold tracking-tight">
          Install a terminal you&apos;ll actually like
        </h1>
        <p className="text-lg text-muted-foreground">
          A good terminal makes everything easier.
        </p>
      </div>

      {/* OS-specific content */}
      {os === "mac" ? <MacContent /> : <WindowsContent />}

      {/* Continue button */}
      <div className="flex justify-end pt-4">
        <Button onClick={handleContinue} disabled={isNavigating} size="lg">
          {isNavigating ? "Loading..." : "I installed it, continue"}
        </Button>
      </div>
    </div>
  );
}
