"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { ArrowLeft, BookOpen, Home, Search } from "lucide-react";
import { Card } from "@/components/ui/card";
import { getAllTerms, type JargonTerm } from "@/lib/jargon";

function toAnchorId(value: string): string {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function matchesQuery(term: JargonTerm, query: string): boolean {
  const haystack = `${term.term} ${term.short} ${term.long}`.toLowerCase();
  return haystack.includes(query);
}

export default function GlossaryPage() {
  const [searchQuery, setSearchQuery] = useState("");

  const allTerms = useMemo(() => {
    const terms = getAllTerms();
    return [...terms].sort((a, b) => a.term.localeCompare(b.term));
  }, []);

  const normalizedQuery = searchQuery.trim().toLowerCase();

  const filteredTerms = useMemo(() => {
    if (!normalizedQuery) return allTerms;
    return allTerms.filter((t) => matchesQuery(t, normalizedQuery));
  }, [allTerms, normalizedQuery]);

  return (
    <div className="relative min-h-screen bg-background">
      {/* Background effects */}
      <div className="pointer-events-none fixed inset-0 bg-gradient-cosmic opacity-50" />
      <div className="pointer-events-none fixed inset-0 bg-grid-pattern opacity-20" />

      <div className="relative mx-auto max-w-4xl px-6 py-8 md:px-12 md:py-12">
        {/* Header */}
        <div className="mb-8 flex items-center justify-between">
          <Link
            href="/learn"
            className="flex items-center gap-2 text-muted-foreground transition-colors hover:text-foreground"
          >
            <ArrowLeft className="h-4 w-4" />
            <span className="text-sm">Learning Hub</span>
          </Link>
          <Link
            href="/"
            className="flex items-center gap-2 text-muted-foreground transition-colors hover:text-foreground"
          >
            <Home className="h-4 w-4" />
            <span className="text-sm">Home</span>
          </Link>
        </div>

        {/* Hero */}
        <div className="mb-10 text-center">
          <div className="mb-4 flex justify-center">
            <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10 shadow-lg shadow-primary/20">
              <BookOpen className="h-8 w-8 text-primary" />
            </div>
          </div>
          <h1 className="mb-3 text-3xl font-bold tracking-tight md:text-4xl">
            Glossary
          </h1>
          <p className="mx-auto max-w-xl text-lg text-muted-foreground">
            Every term used throughout ACFS, explained in plain English.
          </p>
        </div>

        {/* Search */}
        <div className="relative mb-6">
          <Search className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            placeholder="Search terms..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full rounded-xl border border-border/50 bg-card/50 py-3 pl-12 pr-4 text-foreground placeholder:text-muted-foreground focus:border-primary/40 focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
        </div>

        <p className="mb-8 text-sm text-muted-foreground">
          Showing{" "}
          <span className="font-mono text-foreground">
            {filteredTerms.length}
          </span>{" "}
          of{" "}
          <span className="font-mono text-foreground">{allTerms.length}</span>{" "}
          terms.
        </p>

        {/* Terms */}
        <div className="space-y-4">
          {filteredTerms.length > 0 ? (
            filteredTerms.map((term) => {
              const anchorId = toAnchorId(term.term);
              return (
                <Card
                  key={term.term}
                  id={anchorId}
                  className="border-border/50 bg-card/50 p-5 backdrop-blur-sm scroll-mt-28"
                >
                  <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                    <div className="min-w-0">
                      <h2 className="font-mono text-lg font-bold text-foreground">
                        {term.term}
                      </h2>
                      <p className="mt-1 text-sm text-muted-foreground">
                        {term.short}
                      </p>
                    </div>
                    <Link
                      href={`#${anchorId}`}
                      className="text-xs text-muted-foreground hover:text-foreground"
                    >
                      #{anchorId}
                    </Link>
                  </div>

                  <details className="mt-4">
                    <summary className="cursor-pointer text-sm font-medium text-primary/90">
                      Read more
                    </summary>
                    <div className="mt-3 space-y-4 text-sm leading-relaxed text-muted-foreground">
                      <p>{term.long}</p>

                      {term.analogy && (
                        <div className="rounded-xl border border-primary/20 bg-primary/5 p-4">
                          <p className="mb-1 font-medium text-foreground">
                            Think of it like…
                          </p>
                          <p>{term.analogy}</p>
                        </div>
                      )}

                      {term.why && (
                        <div className="rounded-xl border border-border/40 bg-muted/30 p-4">
                          <p className="mb-1 font-medium text-foreground">
                            Why it matters
                          </p>
                          <p>{term.why}</p>
                        </div>
                      )}

                      {term.related && term.related.length > 0 && (
                        <div>
                          <p className="mb-2 font-medium text-foreground">
                            Related
                          </p>
                          <div className="flex flex-wrap gap-2">
                            {term.related.map((related) => {
                              const relatedAnchor = toAnchorId(related);
                              return (
                                <Link
                                  key={related}
                                  href={`#${relatedAnchor}`}
                                  className="rounded-full border border-border/50 bg-card/40 px-3 py-1 text-xs text-muted-foreground hover:border-primary/30 hover:bg-primary/5 hover:text-foreground"
                                >
                                  {related}
                                </Link>
                              );
                            })}
                          </div>
                        </div>
                      )}
                    </div>
                  </details>
                </Card>
              );
            })
          ) : (
            <div className="py-12 text-center">
              <Search className="mx-auto mb-4 h-12 w-12 text-muted-foreground/50" />
              <p className="text-muted-foreground">
                No terms match your search.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

