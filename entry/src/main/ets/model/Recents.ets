import { fileIo } from '@kit.CoreFileKit';

export interface RecentMovie {
  name: string;
  source: string;
  openedAt: number;
}

const MAX_RECENTS = 8;

export class RecentsStore {
  private path: string = '';

  constructor(filesDir: string) {
    this.path = `${filesDir}/recents.json`;
  }

  load(): RecentMovie[] {
    try {
      const text = fileIo.readTextSync(this.path);
      if (text.length === 0) {
        return [];
      }
      const parsed = JSON.parse(text) as RecentMovie[];
      const movies: RecentMovie[] = [];
      for (let i = 0; i < parsed.length && movies.length < MAX_RECENTS; i++) {
        const item = parsed[i];
        if (item && item.name && item.source &&
          !item.source.startsWith('http://') && !item.source.startsWith('https://')) {
          movies.push({
            name: this.decodeName(item.name),
            source: item.source,
            openedAt: item.openedAt ? item.openedAt : 0
          });
        }
      }
      return movies;
    } catch (error) {
      return [];
    }
  }

  add(entry: RecentMovie): RecentMovie[] {
    const movies: RecentMovie[] = [entry];
    const existing = this.load();
    for (let i = 0; i < existing.length; i++) {
      if (existing[i].source !== entry.source && movies.length < MAX_RECENTS) {
        movies.push(existing[i]);
      }
    }
    this.save(movies);
    return movies;
  }

  remove(source: string): RecentMovie[] {
    const movies: RecentMovie[] = [];
    const existing = this.load();
    for (let i = 0; i < existing.length; i++) {
      if (existing[i].source !== source && movies.length < MAX_RECENTS) {
        movies.push(existing[i]);
      }
    }
    this.save(movies);
    return movies;
  }

  clear(): void {
    this.save([]);
  }

  /** Library files moved to a new folder; keep the recents entries openable. */
  rewriteSources(oldPrefix: string, newPrefix: string): RecentMovie[] {
    const movies = this.load();
    let changed = false;
    for (let i = 0; i < movies.length; i++) {
      if (movies[i].source.startsWith(oldPrefix)) {
        movies[i].source = newPrefix + movies[i].source.substring(oldPrefix.length);
        changed = true;
      }
    }
    if (changed) {
      this.save(movies);
    }
    return movies;
  }

  private decodeName(name: string): string {
    try {
      // Heals names persisted by older builds, which stored the picker's raw
      // percent-encoded URI segment (e.g. %E5%BB%BA...swf) instead of the real name.
      return decodeURIComponent(name);
    } catch (error) {
      return name;
    }
  }

  private save(movies: RecentMovie[]): void {
    try {
      const file = fileIo.openSync(this.path,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      try {
        fileIo.writeSync(file.fd, JSON.stringify(movies));
      } finally {
        fileIo.closeSync(file);
      }
    } catch (error) {
      console.error(`recents save failed: ${(error as Error).message}`);
    }
  }
}
