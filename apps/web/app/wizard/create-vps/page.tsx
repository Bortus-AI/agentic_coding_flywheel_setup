"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Check, AlertCircle, Server, ChevronDown } from "lucide-react";
import { Button, Card, Checkbox } from "@/components";
import { cn } from "@/lib/utils";
import { markStepComplete } from "@/lib/wizardSteps";
import { getVPSIP, setVPSIP, isValidIP } from "@/lib/userPreferences";

const CHECKLIST_ITEMS = [
  { id: "ubuntu", label: "Selected Ubuntu 25.x (or newest Ubuntu available)" },
  { id: "ssh", label: "Pasted my SSH public key" },
  { id: "created", label: "Created the VPS and waited for it to start" },
  { id: "copied-ip", label: "Copied the IP address" },
];

interface ProviderGuideProps {
  name: string;
  steps: string[];
  isExpanded: boolean;
  onToggle: () => void;
}

function ProviderGuide({
  name,
  steps,
  isExpanded,
  onToggle,
}: ProviderGuideProps) {
  return (
    <div className="rounded-lg border">
      <button
        type="button"
        onClick={onToggle}
        className="flex w-full items-center justify-between p-3 text-left hover:bg-muted/50"
      >
        <span className="font-medium">{name} specific steps</span>
        <ChevronDown
          className={cn(
            "h-4 w-4 text-muted-foreground transition-transform",
            isExpanded && "rotate-180"
          )}
        />
      </button>
      {isExpanded && (
        <div className="border-t px-3 pb-3 pt-2">
          <ol className="list-decimal space-y-1 pl-5 text-sm text-muted-foreground">
            {steps.map((step, i) => (
              <li key={i}>{step}</li>
            ))}
          </ol>
        </div>
      )}
    </div>
  );
}

const PROVIDER_GUIDES = [
  {
    name: "OVH",
    steps: [
      'Click "Order" on your chosen VPS plan',
      'Under "Image", select Ubuntu 25.04 (or latest)',
      'Under "SSH Key", click "Add a key" and paste your public key',
      "Complete the order and wait for activation email",
      "Copy the IP address from your control panel",
    ],
  },
  {
    name: "Contabo",
    steps: [
      'After ordering, go to "Your services" > "VPS control"',
      'Click "Reinstall" and select Ubuntu 25.x',
      'Under "SSH Key", paste your public key',
      "Wait for the reinstallation to complete",
      "Copy the IP address shown in the control panel",
    ],
  },
  {
    name: "Hetzner",
    steps: [
      'In Cloud Console, click "Add Server"',
      'Select your location and Ubuntu 25.04 image',
      'Under "SSH Keys", add your public key',
      'Click "Create & Buy Now"',
      "Copy the IP address once the server is running",
    ],
  },
];

export default function CreateVPSPage() {
  const router = useRouter();
  const [checkedItems, setCheckedItems] = useState<Set<string>>(new Set());
  const [ipAddress, setIpAddress] = useState("");
  const [ipError, setIpError] = useState<string | null>(null);
  const [expandedProvider, setExpandedProvider] = useState<string | null>(null);
  const [isNavigating, setIsNavigating] = useState(false);

  // Load stored IP on mount
  useEffect(() => {
    const stored = getVPSIP();
    if (stored) {
      setIpAddress(stored);
    }
  }, []);

  const handleCheckItem = useCallback((itemId: string, checked: boolean) => {
    setCheckedItems((prev) => {
      const next = new Set(prev);
      if (checked) {
        next.add(itemId);
      } else {
        next.delete(itemId);
      }
      return next;
    });
  }, []);

  const handleIpChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const value = e.target.value;
      setIpAddress(value);
      setIpError(null);

      if (value && !isValidIP(value)) {
        setIpError("Please enter a valid IP address (e.g., 192.168.1.1)");
      }
    },
    []
  );

  const handleContinue = useCallback(() => {
    if (!ipAddress) {
      setIpError("Please enter your VPS IP address");
      return;
    }
    if (!isValidIP(ipAddress)) {
      setIpError("Please enter a valid IP address");
      return;
    }

    setVPSIP(ipAddress);
    markStepComplete(5);
    setIsNavigating(true);
    router.push("/wizard/ssh-connect");
  }, [ipAddress, router]);

  const allChecked = CHECKLIST_ITEMS.every((item) =>
    checkedItems.has(item.id)
  );
  const canContinue = allChecked && ipAddress && !ipError;

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="space-y-2">
        <h1 className="text-3xl font-bold tracking-tight">
          Create your VPS instance
        </h1>
        <p className="text-lg text-muted-foreground">
          Launch your VPS and attach your SSH key. Follow the checklist below.
        </p>
      </div>

      {/* Universal checklist */}
      <Card className="p-4">
        <h2 className="mb-4 flex items-center gap-2 font-semibold">
          <Server className="h-5 w-5" />
          Setup checklist
        </h2>
        <div className="space-y-3">
          {CHECKLIST_ITEMS.map((item) => (
            <label
              key={item.id}
              className="flex cursor-pointer items-center gap-3"
            >
              <Checkbox
                checked={checkedItems.has(item.id)}
                onCheckedChange={(checked) =>
                  handleCheckItem(item.id, checked === true)
                }
              />
              <span
                className={cn(
                  "text-sm",
                  checkedItems.has(item.id) && "text-muted-foreground line-through"
                )}
              >
                {item.label}
              </span>
            </label>
          ))}
        </div>
      </Card>

      {/* Provider-specific guides */}
      <div className="space-y-3">
        <h2 className="font-semibold">Need help with your provider?</h2>
        {PROVIDER_GUIDES.map((provider) => (
          <ProviderGuide
            key={provider.name}
            name={provider.name}
            steps={provider.steps}
            isExpanded={expandedProvider === provider.name}
            onToggle={() =>
              setExpandedProvider((prev) =>
                prev === provider.name ? null : provider.name
              )
            }
          />
        ))}
      </div>

      {/* IP Address input */}
      <div className="space-y-3">
        <h2 className="font-semibold">Your VPS IP address</h2>
        <p className="text-sm text-muted-foreground">
          Enter the IP address of your new VPS. You&apos;ll find this in your
          provider&apos;s control panel after the VPS is created.
        </p>
        <div className="space-y-2">
          <input
            type="text"
            value={ipAddress}
            onChange={handleIpChange}
            placeholder="e.g., 192.168.1.100"
            className={cn(
              "w-full rounded-md border bg-background px-3 py-2 text-sm outline-none focus:border-primary focus:ring-1 focus:ring-primary",
              ipError && "border-destructive focus:border-destructive focus:ring-destructive"
            )}
          />
          {ipError && (
            <p className="flex items-center gap-1 text-sm text-destructive">
              <AlertCircle className="h-4 w-4" />
              {ipError}
            </p>
          )}
          {ipAddress && !ipError && isValidIP(ipAddress) && (
            <p className="flex items-center gap-1 text-sm text-green-600 dark:text-green-400">
              <Check className="h-4 w-4" />
              Valid IP address
            </p>
          )}
        </div>
      </div>

      {/* Continue button */}
      <div className="flex justify-end pt-4">
        <Button
          onClick={handleContinue}
          disabled={!canContinue || isNavigating}
          size="lg"
        >
          {isNavigating ? "Loading..." : "Continue to SSH"}
        </Button>
      </div>
    </div>
  );
}
