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
        name: 'child-old.txt',
        kind: 'file',
        handle: { id: 'file:child-old.txt', kind: 'file', name: 'child-old.txt' },
        parentHandle: subHandle,
        relativePath: 'sub-folder/child-old.txt',
        size: 48,
        lastModified: now,
      },
    ];

    let hasSavedDirectory = false;

    function directoryRecord() {
      return {
        id: 'root',
        name: 'Root',
        handle: rootHandle,
        permission,
        lastUsedAt: now,
      };
    }

    function cloneEntry(entry: (typeof rootEntries)[number]) {
      return { ...entry };
    }

    function entriesFor(handle: { id: string }) {
      return handle.id === 'sub-folder' ? subEntries : rootEntries;
    }

    const api = {
      isSupported: () => supported,
      pickDirectory: async () => {
        if (!supported) throw new Error('File System Access API is not supported.');
        hasSavedDirectory = true;
        return directoryRecord();
      },
      listSavedDirectories: async () => {
        if (!supported || !hasSavedDirectory) return [];
        return [directoryRecord()];
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

async function openApp(page: Page) {
  await page.goto('/');
  await page.locator('flt-glass-pane').waitFor({ state: 'attached' });

  const semanticsPlaceholder = page.locator('flt-semantics-placeholder');
  if (await semanticsPlaceholder.isVisible().catch(() => false)) {
    await page.evaluate(() => {
      const placeholder = document.querySelector('flt-semantics-placeholder');
      if (placeholder instanceof HTMLElement) placeholder.click();
    });
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
  test('shows the initial folder selection prompt', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);

    await expect(page.getByRole('button', { name: 'フォルダを選択', exact: true })).toBeVisible();
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
    await expect(page.getByRole('button', { name: 'Root', exact: true })).toBeVisible();
    await expect(entryRow(page, 'sub-folder')).toBeVisible();
    await expect(entryRow(page, 'duplicate.txt')).toBeVisible();

    await page.getByRole('button', { name: 'sub-folder フォルダ' }).click();
    await expect(entryRow(page, 'child-old.txt')).toBeVisible();

    await page.getByRole('button', { name: 'Root', exact: true }).click();
    await expect(entryRow(page, 'old-file.txt')).toBeVisible();
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

    await entryRow(page, 'old-file.txt').getByRole('checkbox').click();
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

    await entryRow(page, 'sub-folder').getByRole('checkbox').click();
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

    await entryRow(page, 'old-file.txt').getByRole('checkbox').click();
    await page.keyboard.press('F2');
    await page.keyboard.press('Control+A');
    await page.keyboard.type('manual-new.txt');
    await expect(entryRow(page, 'manual-new.txt')).toHaveCount(0);
    await page.keyboard.press('Enter');
    await expect(entryRow(page, 'manual-new.txt')).toBeVisible();
  });
});
