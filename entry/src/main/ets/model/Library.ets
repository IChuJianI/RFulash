import { fileIo } from '@kit.CoreFileKit';

export interface LibraryMovie {
  name: string;
  source: string;
  thumb: string;
  addedAt: number;
  /** Group name; '' means the file sits in the players root (未分组). */
  group: string;
}

const MAX_LIBRARY = 60;

export class LibraryStore {
  private path: string = '';

  constructor(filesDir: string) {
    this.path = `${filesDir}/library.json`;
  }

  load(): LibraryMovie[] {
    try {
      const text = fileIo.readTextSync(this.path);
      if (text.length === 0) {
        return [];
      }
      const parsed = JSON.parse(text) as LibraryMovie[];
      const movies: LibraryMovie[] = [];
      for (let i = 0; i < parsed.length && movies.length < MAX_LIBRARY; i++) {
        const item = parsed[i];
        if (item && item.name && item.source) {
          movies.push({
            name: item.name,
            source: item.source,
            thumb: item.thumb ? item.thumb : '',
            addedAt: item.addedAt ? item.addedAt : 0,
            group: item.group ? item.group : ''
          });
        }
      }
      return movies;
    } catch (error) {
      return [];
    }
  }

  remove(source: string): LibraryMovie[] {
    const movies: LibraryMovie[] = [];
    const existing = this.load();
    for (let i = 0; i < existing.length; i++) {
      if (existing[i].source !== source && movies.length < MAX_LIBRARY) {
        movies.push(existing[i]);
      }
    }
    this.save(movies);
    return movies;
  }

  /** Overwrites the whole list, used when the players folder is rescanned. */
  replace(movies: LibraryMovie[]): void {
    this.save(movies);
  }

  /** Fills in the thumbnail of entries whose captured PNG just became available. */
  setThumb(name: string, thumb: string): LibraryMovie[] {
    const movies = this.load();
    let changed = false;
    for (let i = 0; i < movies.length; i++) {
      if (movies[i].thumb.length === 0 && movies[i].name === name) {
        movies[i].thumb = thumb;
        changed = true;
      }
    }
    if (changed) {
      this.save(movies);
    }
    return movies;
  }

  private save(movies: LibraryMovie[]): void {
    try {
      const file = fileIo.openSync(this.path,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      try {
        fileIo.writeSync(file.fd, JSON.stringify(movies));
      } finally {
        fileIo.closeSync(file);
      }
    } catch (error) {
      console.error(`library save failed: ${(error as Error).message}`);
    }
  }
}
