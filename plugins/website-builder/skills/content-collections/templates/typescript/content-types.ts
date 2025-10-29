// TypeScript types for content collections

export interface BlogPost {
  title: string;
  description: string;
  date: Date;
  author: string;
  tags: string[];
  draft: boolean;
  image?: string;
}

export interface Documentation {
  title: string;
  description: string;
  category: 'guide' | 'reference' | 'tutorial' | 'api';
  order: number;
  version: string;
  lastUpdated: Date;
}

export interface Project {
  title: string;
  description: string;
  category: 'web' | 'mobile' | 'design' | 'other';
  tags: string[];
  featured: boolean;
  link?: string;
  github?: string;
  date: Date;
}
