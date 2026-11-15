local system = require 'pandoc.system'

local function renderMermaid(code, diagramIndex)
  return system.with_temporary_directory('mermaid-render', function(tmpDir)
    local inFile = tmpDir .. '/diagram.mmd'
    local outFile = tmpDir .. '/diagram.svg'
    local errFile = tmpDir .. '/mmdc.err'

    local f, openErr = io.open(inFile, 'w')
    if not f then
      local msg = string.format('[mermaid.lua] Failed to write temp file: %s', tostring(openErr))
      io.stderr:write(msg .. '\n')
      return nil, msg
    end
    f:write(code)
    f:close()

    -- Redirect stderr to errFile to capture mmdc or Mermaid syntax diagnostics
    local cmd = string.format('mmdc -c mermaid-config.json -i %q -o %q -b transparent 2>%q',
      inFile, outFile, errFile)
    local ok, exitType, exitCode = os.execute(cmd)

    local errDetails = ''
    local ef = io.open(errFile, 'r')
    if ef then
      errDetails = ef:read('*all') or ''
      ef:close()
    end

    if not ok then
      local reason = string.format(
        '[mermaid.lua] Diagram #%d failed (%s: %s).',
        diagramIndex,
        tostring(exitType),
        tostring(exitCode)
      )
      if errDetails ~= '' then
        reason = reason .. '\n' .. errDetails
      else
        reason = reason .. ' Verify that "mmdc" is installed and on your PATH.'
      end
      io.stderr:write(reason .. '\n')
      return nil, reason
    end

    local svgFile = io.open(outFile, 'r')
    if not svgFile then
      local msg = string.format(
        '[mermaid.lua] Diagram #%d: mmdc exited cleanly but no SVG was produced.\n%s',
        diagramIndex,
        errDetails
      )
      io.stderr:write(msg .. '\n')
      return nil, msg
    end

    local svgContent = svgFile:read('*all')
    svgFile:close()
    return svgContent, nil
  end)
end

local function escapeHtml(str)
  return str
    :gsub('&', '&amp;')
    :gsub('<', '&lt;')
    :gsub('>', '&gt;')
end

local diagramCounter = 0

function CodeBlock(block)
  if block.classes:includes('mermaid') then
    diagramCounter = diagramCounter + 1
    local svg, errMsg = renderMermaid(block.text, diagramCounter)

    if svg then
      return pandoc.RawBlock('html', '<div class="mermaid-diagram">' .. svg .. '</div>')
    end

    local errorHtml = string.format(
      '<div class="mermaid-error" style="border: 2px solid #ff5555; background: #2b1111; color: #ffcccc; padding: 1em; font-family: monospace; font-size: 0.6em; text-align: left; white-space: pre-wrap;">'
        .. '<strong>Mermaid Render Error (Diagram #%d)</strong>\n%s\n\n<strong>Source:</strong>\n%s'
        .. '</div>',
      diagramCounter,
      escapeHtml(errMsg or 'Unknown error'),
      escapeHtml(block.text)
    )
    return pandoc.RawBlock('html', errorHtml)
  end
  return nil
end
