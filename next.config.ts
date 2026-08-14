import type { NextConfig } from "next";
import {
  PHASE_DEVELOPMENT_SERVER,
  PHASE_PRODUCTION_SERVER,
} from "next/constants";
import { readServerEnvironment } from "./lib/env";

const projectRoot = import.meta.dirname;

const config: NextConfig = {
  experimental: {
    useTypeScriptCli: false,
  },
  reactStrictMode: true,
  outputFileTracingRoot: projectRoot,
  turbopack: {
    root: projectRoot,
  },
};

export default function nextConfig(phase: string) {
  if (phase === PHASE_DEVELOPMENT_SERVER || phase === PHASE_PRODUCTION_SERVER) {
    readServerEnvironment();
  }
  return config;
}
