import { expect, test, type Page } from '@playwright/test';

type PermissionState = 'granted' | 'prompt' | 'denied';

type RenameryFsMockOptions = {
  supported?: boolean;
  permission?: PermissionState;
};

async function installRenameryFsMock(
  page: Page,
  options: RenameryFsMockOptions = {},
) {
  await page.addInitScript((mockOptions: RenameryFsMockOptions) => {
    window.localStorage.clear();
    window.sessionStorage.clear();

    const supported = mockOptions.supported ?? true;
    let permission = mockOptions.permission ?? 'granted';
    const now = Date.now();

    const rootHandle = { id: 'root', kind: 'directory', name: 'Root' };
    const subHandle = { id: 'sub-folder', kind: 'directory', name: 'sub-folder' };
    const childFolderHandle = { id: 'child-folder', kind: 'directory', name: 'child-folder' };
    const workHandle = { id: 'work', kind: 'directory', name: 'Work' };
    const archiveHandle = { id: 'archive', kind: 'directory', name: 'Archive' };

    const rootEntries = [
      {
        name: 'sub-folder',
        kind: 'directory',
        handle: subHandle,
        parentHandle: rootHandle,
        relativePath: 'sub-folder',
        size: null,
        lastModified: null,
      },
      {
        name: 'old-file.txt',
        kind: 'file',
        handle: { id: 'file:old-file.txt', kind: 'file', name: 'old-file.txt' },
        parentHandle: rootHandle,
        relativePath: 'old-file.txt',
        size: 12,
        lastModified: now,
      },
      {
        name: 'another-old.txt',
        kind: 'file',
        handle: { id: 'file:another-old.txt', kind: 'file', name: 'another-old.txt' },
        parentHandle: rootHandle,
        relativePath: 'another-old.txt',
        size: 24,
        lastModified: now,
      },
      {
        name: 'duplicate.txt',
        kind: 'file',
        handle: { id: 'file:duplicate.txt', kind: 'file', name: 'duplicate.txt' },
        parentHandle: rootHandle,
        relativePath: 'duplicate.txt',
        size: 36,
        lastModified: now,
      },
    ];

    const subEntries = [
      {
        name: 'child-folder',
        kind: 'directory',
        handle: childFolderHandle,
        parentHandle: subHandle,
        relativePath: 'sub-folder/child-folder',
        size: null,
        lastModified: null,
      },
      {
        name: 'child-old.txt',
        kind: 'file',
        handle: { id: 'file:child-old.txt', kind: 'file', name: 'child-old.txt' },
        parentHandle: subHandle,
        relativePath: 'sub-folder/child-old.txt',
        size: 48,
        lastModified: now,
      },
    ];

    const childFolderEntries = [
      {
        name: 'deep-old.txt',
        kind: 'file',
        handle: { id: 'file:deep-old.txt', kind: 'file', name: 'deep-old.txt' },
        parentHandle: childFolderHandle,
        relativePath: 'sub-folder/child-folder/deep-old.txt',
        size: 60,
        lastModified: now,
      },
    ];

    const savedDirectoryIds = new Set<string>();

    function directoryRecord(
      id = 'root',
      name = 'Root',
      handle: { id: string; kind: string; name: string } = rootHandle,
    ) {
      return {
        id,
        name,
        handle,
        permission,
        lastUsedAt: now,
      };
    }

    function directoryRecords() {
      return [
        directoryRecord('root', 'Root', rootHandle),
        directoryRecord('work', 'Work', workHandle),
        directoryRecord('archive', 'Archive', archiveHandle),
      ];
    }

    function cloneEntry(entry: (typeof rootEntries)[number]) {
      return { ...entry };
    }

    function entriesFor(handle: { id: string }) {
      if (handle.id === 'sub-folder') return subEntries;
      if (handle.id === 'child-folder') return childFolderEntries;
      if (handle.id === 'work' || handle.id === 'archive') return [];
      return rootEntries;
    }

    function bytesForHandle(handle: { id: string }) {
      const textById: Record<string, string> = {
        'file:old-file.txt': 'old-file.txt preview text from the browser handle',
        'file:another-old.txt': 'another-old.txt preview text from the browser handle',
        'file:duplicate.txt': 'duplicate.txt preview text from the browser handle',
        'file:child-old.txt': 'child-old.txt preview text from the browser handle',
        'file:deep-old.txt': 'deep-old.txt preview text from the browser handle',
        'file:manual-new.txt': 'manual-new.txt preview text from the browser handle',
      };
      const text = textById[handle.id] ?? `${handle.id} preview text from the browser handle`;
      return new TextEncoder().encode(text);
    }

    const api = {
      isSupported: () => supported,
      pickDirectory: async () => {
        if (!supported) throw new Error('File System Access API is not supported.');
        for (const id of ['root', 'work', 'archive']) savedDirectoryIds.add(id);
        return directoryRecord();
      },
      listSavedDirectories: async () => {
        if (!supported || savedDirectoryIds.size === 0) return [];
        return directoryRecords().filter((record) => savedDirectoryIds.has(record.id));
      },
      forgetSavedDirectory: async (id: string) => {
        savedDirectoryIds.delete(id);
      },
      requestDirectoryPermission: async () => permission,
      listDirectory: async (
        handle: { id: string },
        _relativePath = '',
        recursive = false,
      ) => {
        if (!supported) return [];
        if (permission !== 'granted') throw new Error('Directory permission was not granted.');
        const direct = entriesFor(handle).map(cloneEntry);
        if (!recursive) return direct;
        return direct.flatMap((entry) => {
          if (entry.kind !== 'directory') return [entry];
          return [entry, ...entriesFor(entry.handle).map(cloneEntry)];
        });
      },
      readFileBytes: async (handle: { id: string }, limit = 0) => {
        const bytes = bytesForHandle(handle);
        return limit > 0 ? bytes.slice(0, limit) : bytes;
      },
      renameFile: async (
        parentHandle: { id: string },
        oldName: string,
        newName: string,
      ) => {
        if (permission !== 'granted') throw new Error('Directory permission was not granted.');
        const entries = entriesFor(parentHandle);
        if (entries.some((entry) => entry.name.toLowerCase() === newName.toLowerCase())) {
          throw new Error(`An item named "${newName}" already exists.`);
        }
        const entry = entries.find((item) => item.name === oldName);
        if (!entry) throw new Error(`Missing entry: ${oldName}`);
        const oldRelativePath = entry.relativePath;
        entry.name = newName;
        entry.relativePath = parentHandle.id === 'sub-folder'
          ? `sub-folder/${newName}`
          : newName;
        if (entry.kind === 'file') {
          entry.handle = { id: `file:${newName}`, kind: 'file', name: newName };
        } else {
          entry.handle = { ...entry.handle, name: newName };
          const childPrefix = `${oldRelativePath}/`;
          const nextPrefix = `${entry.relativePath}/`;
          for (const child of entriesFor(entry.handle)) {
            if (child.relativePath.startsWith(childPrefix)) {
              child.relativePath = `${nextPrefix}${child.relativePath.slice(childPrefix.length)}`;
            }
            child.parentHandle = entry.handle;
          }
        }
      },
    };

    Object.defineProperty(window, 'renameryFs', {
      configurable: true,
      get: () => api,
      set: (value) => {
        (window as Window & { __renameryFsReal?: unknown }).__renameryFsReal = value;
      },
    });
  }, options);
}

async function openApp(page: Page, options: { acceptLicense?: boolean } = {}) {
  await page.goto('/');
  await page.locator('flt-glass-pane').waitFor({ state: 'attached' });

  const semanticsPlaceholder = page.locator('flt-semantics-placeholder');
  if (await semanticsPlaceholder.isVisible().catch(() => false)) {
    await page.evaluate(() => {
      const placeholder = document.querySelector('flt-semantics-placeholder');
      if (placeholder instanceof HTMLElement) placeholder.click();
    });
  }

  if (options.acceptLicense === false) return;

  const acceptLicense = page.getByRole('button', { name: '同意して利用を開始する' });
  await acceptLicense.waitFor({ state: 'visible', timeout: 3000 }).catch(() => undefined);
  if (await acceptLicense.isVisible().catch(() => false)) {
    await acceptLicense.click();
    await acceptLicense.waitFor({ state: 'hidden', timeout: 3000 }).catch(() => undefined);
  }
}

function escapeRegExp(value: string) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function entryRow(page: Page, name: string) {
  return page.getByRole('group', {
    name: new RegExp(`^${escapeRegExp(name)}(\\s|$)`),
  });
}

async function openMockDirectory(page: Page) {
  await page.getByRole('button', { name: 'ローカルフォルダを選択' }).click();
  await expect(entryRow(page, 'old-file.txt')).toBeVisible();
}

test.describe('ReNamery Web MVP', () => {
  test('requires license agreement on first launch', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page, { acceptLicense: false });

    await expect(page.getByText('ソフトウェア利用規約')).toBeVisible();
    await expect(page.getByRole('button', { name: '同意して利用を開始する' })).toBeVisible();
  });

  test('explains that declining cannot close the browser tab', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page, { acceptLicense: false });

    await page.getByRole('button', { name: '同意しない（アプリを終了する）' }).click();

    await expect(page.getByText('アプリを終了できません')).toBeVisible();
    await page.getByRole('button', { name: '閉じる' }).click();
    await expect(page.getByText('ソフトウェア利用規約')).toBeVisible();
  });

  test('shows the initial folder selection prompt', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);

    await expect(page.getByRole('button', { name: 'ローカルフォルダを選択' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'フォルダを選択', exact: true })).toBeVisible();
  });

  test('exposes app and publisher metadata', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);

    await expect(page).toHaveTitle(/ReNamery/);
    await expect(page).toHaveTitle(/東洋クラフト/);
    await expect(page.locator('html')).toHaveAttribute('lang', 'ja');
    await expect(page.locator('meta[name="application-name"]')).toHaveAttribute('content', 'ReNamery');
    await expect(page.locator('meta[name="author"]')).toHaveAttribute('content', '東洋クラフト');
    await expect(page.locator('meta[name="publisher"]')).toHaveAttribute('content', '東洋クラフト');
    await expect(page.locator('link[rel="canonical"]')).toHaveAttribute('href', 'https://toyo-craft.net/apps');
    await expect(page.locator('meta[property="og:site_name"]')).toHaveAttribute('content', '東洋クラフト');
  });

  test('shows unsupported browser guidance', async ({ page }) => {
    await installRenameryFsMock(page, { supported: false });
    await openApp(page);

    await expect(page).toHaveTitle(/ReNamery/);
    await expect(page.getByText('このブラウザはフォルダ連携に対応していません')).toBeVisible();
  });

  test('opens a mocked local directory and navigates entries', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);

    await openMockDirectory(page);
    await expect(page.getByText('PC', { exact: true })).toHaveCount(0);
    await expect(page.getByText('フォルダ', { exact: true })).toHaveCount(0);
    await expect(page.getByText('OSドライブ一覧はブラウザ制約により利用できません')).toHaveCount(0);
    await expect(page.getByText('任意パス移動はWeb版では利用できません')).toHaveCount(0);
    await expect(page.getByRole('button', { name: 'Root フォルダ' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Work フォルダ' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Archive フォルダ' })).toBeVisible();
    await expect(entryRow(page, 'sub-folder')).toBeVisible();
    await expect(entryRow(page, 'duplicate.txt')).toBeVisible();
    await expect(page.getByRole('button', { name: 'sub-folder フォルダ' })).toBeVisible();

    await page.getByRole('button', { name: 'sub-folder フォルダ' }).click();
    await expect(entryRow(page, 'child-old.txt')).toBeVisible();
    await expect(page.getByRole('button', { name: 'child-folder フォルダ' })).toBeVisible();

    await page.getByRole('button', { name: 'Root フォルダ' }).click();
    await expect(entryRow(page, 'old-file.txt')).toBeVisible();
  });

  test('forgets saved directories from quick access', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);
    await openMockDirectory(page);

    await page.getByRole('button', { name: 'クイックアクセスから解除' }).first().click();
    await expect(page.getByText('クイックアクセスから解除しますか？')).toBeVisible();
    await expect(page.getByText('「Root」をReNameryのクイックアクセスから解除します。')).toBeVisible();
    await page.getByRole('button', { name: 'キャンセル' }).click();
    await expect(page.getByText('クイックアクセスから解除しますか？')).toHaveCount(0);
    await expect(page.getByRole('button', { name: 'Root フォルダ' })).toBeVisible();

    await page.getByRole('button', { name: 'クイックアクセスから解除' }).first().click();
    await page.getByRole('button', { name: /^解除$/ }).click();
    await expect(page.getByText('クイックアクセスから解除しました').first()).toBeVisible();
    await expect(page.getByRole('button', { name: 'Root フォルダ' })).toHaveCount(0);

    await page.getByRole('button', { name: 'クイックアクセスから解除' }).first().click();
    await expect(page.getByText('「Work」をReNameryのクイックアクセスから解除します。')).toBeVisible();
    await page.getByRole('button', { name: /^解除$/ }).click();
    await expect(page.getByRole('button', { name: 'Work フォルダ' })).toHaveCount(0);
  });

  test('selects and clears all listed entries', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);
    await openMockDirectory(page);

    await page.getByRole('button', { name: 'すべて選択' }).click();
    await expect(page.getByRole('button', { name: '選択解除' })).toBeVisible();

    await page.getByRole('button', { name: '選択解除' }).click();
    await expect(page.getByRole('button', { name: 'すべて選択' })).toBeVisible();
  });

  test('shows shared preview for web text file content', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);
    await openMockDirectory(page);

    await entryRow(page, 'old-file.txt').click();

    await expect(
      page.locator('[aria-label*="old-file.txt preview text from the browser handle"]'),
    ).toBeVisible();
    await expect(
      page.locator('[aria-label*="Web版ではTXTファイルの内容プレビューは未対応です。"]'),
    ).toHaveCount(0);
  });

  test('shows child directory files when recursive search is enabled', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);
    await openMockDirectory(page);

    await expect(entryRow(page, 'child-old.txt')).toHaveCount(0);
    await page.getByRole('button', { name: '下位フォルダ' }).click();

    await expect(entryRow(page, 'child-old.txt')).toBeVisible();
    await expect(page.getByRole('button', { name: 'sub-folder フォルダ' })).toBeVisible();
  });

  test('renames a file from inline edit', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);
    await openMockDirectory(page);

    await entryRow(page, 'old-file.txt').click();
    await page.keyboard.press('F2');
    await page.keyboard.press('Control+A');
    await page.keyboard.type('manual-new.txt');
    await page.keyboard.press('Enter');

    await expect(entryRow(page, 'manual-new.txt')).toBeVisible();
    await expect(entryRow(page, 'old-file.txt')).toHaveCount(0);

    await page.getByRole('button', { name: '戻す' }).first().click();
    await page.getByRole('button', { name: /復元|戻す/ }).last().click();
    await expect(entryRow(page, 'old-file.txt')).toBeVisible();
    await expect(entryRow(page, 'manual-new.txt')).toHaveCount(0);
  });

  test('renames a folder from inline edit', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);
    await openMockDirectory(page);

    await entryRow(page, 'sub-folder').click();
    await page.keyboard.press('F2');
    await page.keyboard.press('Control+A');
    await page.keyboard.type('renamed-folder');
    await page.keyboard.press('Enter');

    await expect(entryRow(page, 'renamed-folder')).toBeVisible();
    await expect(entryRow(page, 'sub-folder')).toHaveCount(0);

    await page.getByRole('button', { name: 'renamed-folder フォルダ' }).click();
    await expect(entryRow(page, 'child-old.txt')).toBeVisible();
  });

  test('keeps inline edit focused until submitted', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);
    await openMockDirectory(page);

    await entryRow(page, 'old-file.txt').click();
    await page.keyboard.press('F2');
    await page.keyboard.press('Control+A');
    await page.keyboard.type('manual-new.txt');
    await expect(entryRow(page, 'manual-new.txt')).toHaveCount(0);
    await page.keyboard.press('Enter');
    await expect(entryRow(page, 'manual-new.txt')).toBeVisible();
  });
});
