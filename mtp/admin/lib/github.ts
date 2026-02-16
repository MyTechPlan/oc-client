import { Octokit } from '@octokit/rest'

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN })

function parseRepo(repo: string) {
  const [owner, name] = repo.split('/')
  return { owner, repo: name }
}

export interface GHFile {
  path: string
  name: string
  type: 'file' | 'dir'
  sha?: string
}

export interface TreeNode {
  name: string
  path: string
  type: 'file' | 'dir'
  children?: TreeNode[]
}

const IGNORED_DIRS = new Set(['.git', 'node_modules', '.next', '.vercel', '__pycache__', '.turbo', '.cache'])
const IGNORED_FILES = new Set(['package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', '.DS_Store'])
const BINARY_EXTS = new Set(['.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.svg', '.xlsx', '.xls', '.pdf', '.zip', '.tar', '.gz', '.mp3', '.mp4', '.woff', '.woff2', '.ttf', '.eot'])

function isBinary(path: string): boolean {
  const ext = path.substring(path.lastIndexOf('.')).toLowerCase()
  return BINARY_EXTS.has(ext)
}

function isIgnored(path: string): boolean {
  const parts = path.split('/')
  return parts.some(p => IGNORED_DIRS.has(p)) || IGNORED_FILES.has(parts[parts.length - 1])
}

export async function listTree(repo: string): Promise<{ tree: TreeNode[]; basePath: string }> {
  const { owner, repo: repoName } = parseRepo(repo)
  try {
    // Get default branch
    const { data: repoData } = await octokit.repos.get({ owner, repo: repoName })
    const branch = repoData.default_branch

    const { data } = await octokit.git.getTree({ owner, repo: repoName, tree_sha: branch, recursive: 'true' })

    // Detect if this is a workspace-based repo (Vesta) or root-based (Enki)
    const hasWorkspace = data.tree.some(item => item.path?.startsWith('workspace/'))
    const basePath = hasWorkspace ? 'workspace' : ''

    // Filter and build tree
    const items = data.tree.filter(item => {
      if (!item.path || !item.type) return false
      // If workspace-based, only show workspace/ contents
      if (hasWorkspace) {
        if (!item.path.startsWith('workspace/')) return false
      }
      const relativePath = hasWorkspace ? item.path.substring('workspace/'.length) : item.path
      if (!relativePath) return false
      if (isIgnored(relativePath)) return false
      if (item.type === 'blob' && isBinary(relativePath)) return false
      return item.type === 'blob' || item.type === 'tree'
    })

    // Build hierarchical tree
    const root: TreeNode[] = []
    const dirMap = new Map<string, TreeNode>()

    // Sort: dirs first, then files, alphabetically
    const sorted = items.sort((a, b) => {
      const aPath = a.path!
      const bPath = b.path!
      return aPath.localeCompare(bPath)
    })

    for (const item of sorted) {
      const fullPath = item.path!
      const relativePath = hasWorkspace ? fullPath.substring('workspace/'.length) : fullPath
      const parts = relativePath.split('/')
      const name = parts[parts.length - 1]
      const type = item.type === 'tree' ? 'dir' : 'file'

      const node: TreeNode = { name, path: fullPath, type }
      if (type === 'dir') {
        node.children = []
        dirMap.set(relativePath, node)
      }

      if (parts.length === 1) {
        root.push(node)
      } else {
        const parentRelative = parts.slice(0, -1).join('/')
        const parent = dirMap.get(parentRelative)
        if (parent && parent.children) {
          parent.children.push(node)
        }
      }
    }

    // Sort each level: dirs first, then files
    const sortNodes = (nodes: TreeNode[]) => {
      nodes.sort((a, b) => {
        if (a.type !== b.type) return a.type === 'dir' ? -1 : 1
        return a.name.localeCompare(b.name)
      })
      for (const n of nodes) {
        if (n.children) sortNodes(n.children)
      }
    }
    sortNodes(root)

    return { tree: root, basePath }
  } catch (e) {
    console.error('listTree error:', e)
    return { tree: [], basePath: '' }
  }
}

export async function listFiles(repo: string, path: string = ''): Promise<GHFile[]> {
  const { owner, repo: repoName } = parseRepo(repo)
  try {
    const { data } = await octokit.repos.getContent({ owner, repo: repoName, path: path || '.' })
    if (!Array.isArray(data)) return []
    return data.map(f => ({ path: f.path, name: f.name, type: f.type as 'file' | 'dir', sha: f.sha }))
  } catch {
    return []
  }
}

export async function getFile(repo: string, path: string): Promise<{ content: string; sha: string } | null> {
  const { owner, repo: repoName } = parseRepo(repo)
  try {
    const { data } = await octokit.repos.getContent({ owner, repo: repoName, path }) as any
    if (data.type !== 'file') return null
    const content = Buffer.from(data.content, 'base64').toString('utf-8')
    return { content, sha: data.sha }
  } catch {
    return null
  }
}

export interface CronJob {
  id: string
  name: string
  enabled: boolean
  schedule: { kind: string; expr: string; tz: string }
  sessionTarget?: string
  payload: { kind: string; message: string; timeoutSeconds?: number }
  delivery?: { mode: string }
  state?: { nextRunAtMs?: number }
}

export async function getCronJobs(repo: string): Promise<CronJob[]> {
  const file = await getFile(repo, '.openclaw/cron/jobs.json')
  if (!file) return []
  try {
    const data = JSON.parse(file.content)
    return data.jobs || []
  } catch {
    return []
  }
}

export async function updateFile(repo: string, path: string, content: string, sha: string, message?: string): Promise<boolean> {
  const { owner, repo: repoName } = parseRepo(repo)
  try {
    await octokit.repos.createOrUpdateFileContents({
      owner, repo: repoName, path,
      message: message || `Update ${path} via TaaS Admin`,
      content: Buffer.from(content).toString('base64'),
      sha,
    })
    return true
  } catch (e) {
    console.error('GitHub update error:', e)
    return false
  }
}
