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
      listDirectory: async (handle: { id: string }) => {
        if (!supported) return [];
        if (permission !== 'granted') throw new Error('Directory permission was not granted.');
        return entriesFor(handle).map(cloneEntry);
      },
      renameFile: async (
        parentHandle: { id: string },
        oldName: string,
        newName: string,
      ) => {
        if (permission !== 'granted') throw new Error('Directory permission was not granted.');
        const entries = entriesFor(parentHandle);
        if (entries.some((entry) => entry.name.toLowerCase() === newName.toLowerCase())) {
          throw new Error(`A file named "${newName}" already exists.`);
        }
        const entry = entries.find((item) => item.name === oldName);
        if (!entry || entry.kind !== 'file') throw new Error(`Missing file: ${oldName}`);
        entry.name = newName;
        entry.relativePath = parentHandle.id === 'sub-folder'
          ? `sub-folder/${newName}`
          : newName;
        entry.handle = { id: `file:${newName}`, kind: 'file', name: newName };
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
    name: new RegExp(`(^|\\s)${escapeRegExp(name)}(\\s|$)`),
  });
}

async function fillTextBox(page: Page, name: string, value: string) {
  const textBox = page.getByRole('textbox', { name });
  await textBox.click();
  await page.keyboard.press('Control+A');
  await page.keyboard.type(value);
  await expect(textBox).toHaveValue(value);
}

async function openMockDirectory(page: Page) {
  await page.getByRole('button', { name: 'ローカルフォルダを選択' }).click();
  await expect(entryRow(page, 'old-file.txt')).toBeVisible();
}

test.describe('ReNamery Web MVP', () => {
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

    await page.getByRole('button', { name: '開く' }).click();
    await expect(entryRow(page, 'child-old.txt')).toBeVisible();

    await page.getByRole('button', { name: 'Root', exact: true }).click();
    await expect(entryRow(page, 'old-file.txt')).toBeVisible();
  });

  test('previews and executes a file rename', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);
    await openMockDirectory(page);

    await entryRow(page, 'old-file.txt').getByRole('checkbox').click();
    await expect(page.getByRole('group', { name: /選択中: 1 件/ })).toBeVisible();

    await fillTextBox(page, '検索文字列', 'old');
    await fillTextBox(page, '置換後文字列', 'new');
    await page.getByRole('button', { name: '選択中に適用' }).first().click();

    await expect(entryRow(page, 'new-file.txt')).toBeVisible();
    await expect(page.getByRole('button', { name: 'ファイルリネームを実行' })).toBeEnabled();

    await page.getByRole('button', { name: 'ファイルリネームを実行' }).click();
    await expect(entryRow(page, 'new-file.txt')).toBeVisible();
    await expect(entryRow(page, 'old-file.txt')).toHaveCount(0);
  });

  test('blocks execution when preview creates a duplicate name', async ({ page }) => {
    await installRenameryFsMock(page);
    await openApp(page);
    await openMockDirectory(page);

    await entryRow(page, 'old-file.txt').getByRole('checkbox').click();
    await fillTextBox(page, '検索文字列', 'old-file');
    await fillTextBox(page, '置換後文字列', 'duplicate');
    await page.getByRole('button', { name: '選択中に適用' }).first().click();

    await expect(entryRow(page, 'duplicate.txt')).toHaveCount(2);
    await expect(page.getByRole('button', { name: 'ファイルリネームを実行' })).toBeDisabled();
    await expect(page.getByText('フォルダーリネームは後続対応です')).toBeVisible();
  });
});
