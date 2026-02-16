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
