local system = require 'pandoc.system'
local string = require 'string'


local block_filter = {
  RawInline = function (el)
    return RawInline(el)
  end,
  OrderedList = function (el)
    return OrderedList(el)
  end,
  Table = function (el)
    return Table(el)
  end,
  RawBlock = function (el)
    return RawBlock(el)
  end,
  Header = function (el)
    return Header(el)
  end
}
local inline_filter = {
  RawInline = function (el)
    return RawInline(el)
  end
}

function dump(o) --- for printing a table
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]  --corrected bug. if t1[#t1+i] is used, indices will be skipped
    end
    return t1
end

-- Utility function to generate a random alphanumeric string of length 2
local function random_string()
  local chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
  local length = 2
  local result = ''
  for i = 1, length do
    local rand_index = math.random(#chars)
    result = result .. chars:sub(rand_index, rand_index)
  end
  return result
end

-- Table to keep track of used random strings to ensure uniqueness
local used_strings = {}

-- Function to generate a unique random string
local function unique_random_string()
  local str
  repeat
    str = random_string()
  until not used_strings[str]
  used_strings[str] = true
  return str
end

local function strip_environment(el,env)
  local el_text = el.text:match("\\begin{" .. env .. "}(.-)\\end{" .. env .. "}")
  local el_read = pandoc.read(el_text,'latex+raw_tex').blocks
  return el_read
end

local function strip_environment_opts(el,env)
  local el_text = el.text:match("\\begin{" .. env .. "}%[.-%](.-)\\end{" .. env .. "}") -- this is giving nil
  local el_read = pandoc.read(el_text,'latex+raw_tex').blocks
  return el_read
end

-- local function strip_environment_mismatched(el,env1,env2)
--   local el_text = el.text:match("\\begin{" .. env1 .. "}(.-)\\end{" .. env2 .. "}")
--   -- Make the second part, after the begin{env2} to the end of the text, a separate text
--   local el_text2 = el_text:match("\\begin{" .. env2 .. "}(.-)$")
--   -- Make the first part, from the beginning of the text to end{env1} a separate text
--   local el_text1 = el_text:match("^(.-)\\end{" .. env1 .. "}")
--   -- Read the first part as a block
--   local el_read1 = pandoc.read(el_text1,'latex+raw_tex').blocks
--   -- Read the second part as a block
--   local el_read2 = pandoc.read(el_text2,'latex+raw_tex').blocks
--   -- Return both blocks
--   return el_read1,el_read2
-- end

-- local function strip_environment_mismatched_opts(el,env1,env2)
--   local el_text = el.text:match("\\begin{" .. env1 .. "}%[.-%](.-)\\end{" .. env2 .. "}")
--   -- Make the second part, after the begin{env2} to the end of the text, a separate text
--   local el_text2 = el_text:match("\\begin{" .. env2 .. "}(.-)$")
--   -- Make the first part, from the beginning of the text to end{env1} a separate text
--   local el_text1 = el_text:match("^(.-)\\end{" .. env1 .. "}")
--   -- Read the first part as a block
--   local el_read1 = pandoc.read(el_text1,'latex+raw_tex').blocks
--   -- Read the second part as a block
--   local el_read2 = pandoc.read(el_text2,'latex+raw_tex').blocks
--   -- Return both blocks
--   return el_read1,el_read2
-- end

local function starts_with(start, str)
  return str:sub(1, #start) == start
end

local function keyworder(element)
  local main_text = element.text:match("{(.-)}")
  return pandoc.Span(main_text,{class='keyword'})
end

local function clozer(element)
  local main_text = element.text:match("{(.-)}")
  return pandoc.Span(main_text,{class='cloze'})
end

local function clozer_block(element)
  local main_text = element.text:match("{(.-)}")
  return pandoc.Para(main_text,{class='cloze'})
end

local function referencer(element)
  local main_text = element.text:match("{(.-)}")
  return pandoc.RawInline('markdown',"[@" .. main_text .. "]")
end

local function urler(element)
  local main_text = element.text:match("{(.-)}")
  return pandoc.Span(
      pandoc.RawInline('markdown',"[" .. main_text .. "](" .. main_text .. ")"),
      {class='myurl'}
    )
end

local function keyer(element)
  local main_text = element.text:match("{(.-)}")
  return pandoc.Span(
      pandoc.Str(main_text),
      {class='key'}
    )
end

local function mpyer(element)
  local main_text = element.text:match("{(.-)}")
  return pandoc.Code(main_text,{class="python"})
end

local function mcer(element)
  local main_text = element.text:match("{(.-)}")
  return pandoc.Code(main_text,{class="c"})
end

local function mber(element)
  local main_text = element.text:match("{(.-)}")
  return pandoc.Code(main_text,{class="bash"})
end

local function exa_get_problem(element,environment)
  local main_text = element.text:match("^\\begin{" .. environment .. "}(.-)\\tcblower")
  main_text = pandoc.read(main_text,'latex+raw_tex').blocks
  return pandoc.Div(main_text,{})
end

local function exa_get_solution(element,environment)
  local main_text = element.text:match("\\tcblower(.-)\\end{" .. environment .. "}")
  main_text = pandoc.read(main_text,'latex+raw_tex').blocks
  return pandoc.Div(main_text,{class='example-solution'})
end

local function replace_myexample(el)
  problem = exa_get_problem(el,'myexample')
  solution = exa_get_solution(el,'myexample')
  return {problem,solution}
end

local function replace_myexamplealways(el)
  problem = exa_get_problem(el,'myexamplealways')
  solution = exa_get_solution(el,'myexamplealways')
  return {problem,solution}
end

local function Definition_get_name(element)
  local main_text = element.text:match("\\begin{Definition}{(.-)}")
  return main_text
end

local function Definition_get_ref(element)
  local main_text = element.text:match("\\begin{Definition}{.-}{(.-)}")
  return main_text
end

local function Definition_get(element)
  local main_text = element.text:match("\\begin{Definition}{.-}{.-}(.-)\\end{Definition}")
  return main_text
end

local function replace_Definition(el)
  local name = Definition_get_name(el)
  local ref = Definition_get_ref(el)
  local definition = Definition_get(el)
  -- Parse the definition text as latex
  definition = pandoc.read(definition,'latex+raw_tex').blocks
  return pandoc.Div(definition,{ref,{"definition"}})
end

local function infobox_get_name(element)
  local main_text = element.text:match("\\begin{infobox}%[(.-)%]")
  return main_text
end

local function infobox_get_ref(element)
  local main_text = element.text:match("\\label{(.-)}")
  return main_text
end

local function infobox_get(element)
  local main_text = element.text:match("\\begin{infobox}%[.-%](.-)\\end{infobox}")
  return main_text
end

local function replace_infobox(el)
  local name = infobox_get_name(el)
  local ref = infobox_get_ref(el)
  local contents = pandoc.Div(
      pandoc.read(infobox_get(el),'latex+raw_tex').blocks,
      {'infobox_contents'}
    )
  return pandoc.Div(
    {
      pandoc.Div(pandoc.Para(name),{'infobox_name'}),
      contents
    },
    {ref or 'labelme',{'infobox'}}
  )
end

local function replace_exercise(el)
  -- Extract the ID attribute from the exercise environment
  local id
  local id1 = el.text:match("ID=(.-),")
  local id2 = el.text:match("ID=(.-)%]")
  if id1 == nil and id2 == nil then
    id = "IDME"
  elseif id1 == nil then
    id = id2
  elseif id2 == nil then
    id = id1
  else
    id = id1  -- Take the first one (the one before the comma)
  end
  local exercise
  if el.text:match("\\begin{exercise}%[") == nil then
    exercise = strip_environment(el,'exercise')
  else
    exercise = strip_environment_opts(el,'exercise')
  end
  local exercise_div = pandoc.Div(
    exercise,
    {id,{'exercise'}}
  )
  exercise_div.attributes['h'] = id
  -- Turn into a raw markdown block
  local exercise_div_raw = pandoc.write(pandoc.Pandoc(exercise_div), "markdown")
  --- Remove the last occurrence of :::
  exercise_div_raw = exercise_div_raw:gsub("(.*):::","%1")
  return pandoc.RawBlock('markdown',exercise_div_raw)
end

local function replace_solution(el)
  local solution
  if el.text:match("\\begin{solution}%[") == nil then
    solution = strip_environment(el,'solution')
  else
    solution = strip_environment_opts(el,'solution')
  end
  local solution_div = pandoc.Div(
    solution,
    {class='exercise-solution'}
  )
  -- Turn into a raw markdown block
  local solution_div_raw = pandoc.write(pandoc.Pandoc(solution_div), "markdown")
  --- Append a closing ::: to the end
  solution_div_raw = solution_div_raw .. "\n:::"
  return pandoc.RawBlock('markdown',solution_div_raw)
end

local function replace_subfile(el)
  local filename = el.text:match("\\subfile{(.-)}")
  local f = assert(io.open(filename .. ".tex", "rb"))
  local content = f:read("*all")
  f:close()
  local tex_contents = pandoc.Div(
    pandoc.read(content,'latex+raw_tex').blocks
  )
  return pandoc.walk_block(
    tex_contents,
    block_filter
  ).content
end

local function replace_input(el)
  local filename = el.text:match("\\input{(.-)}")
  -- if there is no .tex extension, add it
  if not string.match(filename,"%.tex$") then
    filename = filename .. ".tex"
  end
  local f = assert(io.open(filename, "rb"))
  local content = f:read("*all")
  f:close()
  local tex_contents = pandoc.Div(
    pandoc.read(content,'latex+raw_tex').blocks
  )
  return pandoc.walk_block(
    tex_contents,
    block_filter
  ).content
end

local function replace_resource(el)
  local title = pandoc.walk_inline(
    pandoc.Str(
      el.text:match("\\resource{.-}{(.-)}")
    ),
    inline_filter
  )
  local ref = el.text:match("\\resource{.-}{.-}{(.-)}")
  return pandoc.Header(2,title,{ref or 'labelme',{'resource'}})
end

local function replace_todolist(el)
  local el_text_itemize = el.text:gsub("{todolist}","{itemize}")
  local el_text_itemize = el_text_itemize:gsub("\\item[.-]","\\item")
  local el_read = pandoc.read(el_text_itemize,'latex+raw_tex').blocks
  return el_read
end

local function boarder(el)
  if starts_with('\\boardsubsec', el.text) then
    hlevel = 3
    command_match = el.text:match("\\boardsubsec{(.-)}")
  else
    hlevel = 2
    command_match = el.text:match("\\board{(.-)}")
  end
  local title = pandoc.walk_inline(
    pandoc.Str(
      command_match
    ),
    inline_filter
  )
  return pandoc.Header(hlevel,title,{'labelme'})
end

local function boarder_inline(el)
  if starts_with('\\boardsubsec', el.text) then
    hlevel = 3
    hmd = "###"
    command_match = el.text:match("\\boardsubsec{(.-)}")
  else
    hlevel = 2
    hmd = "##"
    command_match = el.text:match("\\board{(.-)}")
  end
  return pandoc.RawInline('markdown',
       "\n\n" .. hmd .. " " .. command_match .. "\n\n"
    )
end

local function replace_textbook(el)
  local con = el.text:match("\\begin{textbook}(.-)\\end{textbook}")
  local tex_contents = pandoc.Div(
    pandoc.read(con,'latex+raw_tex').blocks
  )
  return pandoc.Div(
    pandoc.walk_block(
      tex_contents,
      block_filter
    ).content,
    {class='textbook'}
  )
end

local function replace_definition(el)
  local name = el.text:match("\\begin{definition}[(.-)]")
  if name == nil then
    name = ''
    con = el.text:match("\\begin{definition}(.-)\\end{definition}")
  else
    con = el.text:match("\\begin{definition}[.-](.-)\\end{definition}")
  end
  local tex_contents = pandoc.Div(
    pandoc.read(con,'latex+raw_tex').blocks,
    {class='definition'}
  )
  return tex_contents
end

local function replace_theorem(el)
  local name = el.text:match("\\begin{theorem}[(.-)]")
  local label = el.text:match("\\label{(.-)}")
  el.text = el.text:gsub("\\label{(.-)}","")
  if name == nil then
    name = ''
    con = el.text:match("\\begin{theorem}(.-)\\end{theorem}")
  else
    con = el.text:match("\\begin{theorem}[.-](.-)\\end{theorem}")
  end
  local tex_contents = pandoc.Div(
    pandoc.read(con,'latex+raw_tex').blocks,
    {class='theorem',id=label}
  )
  return tex_contents
end

local function replace_lemma(el)
  local name = el.text:match("\\begin{lemma}[(.-)]")
  local label = el.text:match("\\label{(.-)}")
  el.text = el.text:gsub("\\label{(.-)}","")
  if name == nil then
    name = ''
    con = el.text:match("\\begin{lemma}(.-)\\end{lemma}")
  else
    con = el.text:match("\\begin{lemma}[.-](.-)\\end{lemma}")
  end
  local tex_contents = pandoc.Div(
    pandoc.read(con,'latex+raw_tex').blocks,
    {class='lemma',id=label}
  )
  return tex_contents
end

local function replace_notes(el)
  local con = el.text:match("%b{}")
  local tex_contents = pandoc.Div(
    pandoc.read(con,'latex+raw_tex').blocks,
    {class='notes marginnote'}
  )
  return tex_contents
end

local function replace_maybeeq(el)
  -- Replace \maybeeq{...} with its contents
  -- get text between {} but not the braces, recognizing that there can be braces in the text
  local con = el.text:match("%b{}")
  -- strip outer braces
  con = con:sub(2,-2)
  -- strip only leading % and \n, if they are in the first two characters
  con = con:gsub("^%s*%%?%s*","")
  -- if it is wrapped in \begin{align}...\end{align} or \begin{align*}...\end{align*}, replace the wrapping align or align* with $$\begin{aligned}...\end{aligned}$$ and remove trailing whitespace before \end{aligned}
  con = con:gsub("\\begin{align%*?}(.-)\\end{align%*?}",function (x) return "$$\\begin{aligned}" .. x:gsub("%s*$","") .. "\\end{aligned}$$" end)
  local tex_contents = pandoc.RawBlock('markdown',
    con,
    {class='maybe maybeeq'}
  )
  return tex_contents
end

local function replace_maybeeqn(el)
  -- -- Replace \maybeeq{...} with its contents
  -- -- get text between {} but not the braces, recognizing that there can be braces in the text
  -- local id = el.text:match("\\maybeeqn{.-}{(.-)}{.-}")
  -- local con = el.text:match("\\maybeeqn{.-}{.-}{(.-)}")
  -- -- strip outer braces
  -- con = con:sub(2,-2)
  -- -- strip only leading % and \n, if they are in the first two characters
  -- con = con:gsub("^%s*%%?%s*","")
  -- -- if it is wrapped in \begin{align}...\end{align} or \begin{align*}...\end{align*}, replace the wrapping align or align* with $$\begin{aligned}...\end{aligned}$$
  -- con = con:gsub("\\begin{align%*?}(.-)\\end{align%*?}",function (x) return "$$\\begin{aligned}" .. x:gsub("%s*$","") .. "\\end{aligned}$$" end)
  -- local tex_contents = pandoc.RawBlock(
  --   con,
  --   {class='maybe maybeeq'}
  -- )
  -- return tex_contents
  return el
end

local function replace_maybeeq_inline(el)
  -- Replace \maybeeq{...} with its contents
  -- get text between {} but not the braces, recognizing that there can be braces in the text
  local con = el.text:match("%b{}")
  -- strip outer braces
  con = con:sub(2,-2)
  -- strip only leading % and \n, if they are in the first two characters
  con = con:gsub("^%s*%%?%s*","")
  -- if it is wrapped in \begin{align}...\end{align} or \begin{align*}...\end{align*}, replace the wrapping align or align* with $$\begin{aligned}...\end{aligned}$$
  con = con:gsub("\\begin{align%*?}(.-)\\end{align%*?}",function (x) return "$$\\begin{aligned}" .. x:gsub("%s*$","") .. "\\end{aligned}$$" end)
  local tex_contents = pandoc.RawInline('markdown',
    con,
    {class='maybe maybeeq'}
  )
  return tex_contents
end

local function replace_maybeeqn_inline(el)
  -- Replace \maybeeq{...} with its contents
  -- get text between {} but not the braces, recognizing that there can be braces in the text
  local id = el.text:match("\\maybeeqn{.-}{(.-)}{.-}")
  local con = el.text:match("\\maybeeqn{.-}{.-}{(.-)}")
  -- strip outer braces
  con = con:sub(2,-2)
  -- strip only leading % and \n, if they are in the first two characters
  con = con:gsub("^%s*%%?%s*","")
  -- if it is wrapped in \begin{align}...\end{align} or \begin{align*}...\end{align*}, replace the wrapping align or align* with $$\begin{aligned}...\end{aligned}$$
  con = con:gsub("\\begin{align%*?}(.-)\\end{align%*?}",function (x) return "$$\\begin{aligned}" .. x:gsub("%s*$","") .. "\\end{aligned}$$" end)
  local tex_contents = pandoc.RawInline('markdown',
    con,
    {id=id,class='maybe maybeeq'}
  )
  return tex_contents
end

local function replace_mayb(el)
  -- Replace \mayb{...} with its contents
  -- get text between {} but not the braces, recognizing that there can be braces in the text
  local con = el.text:match("%b{}")
  -- strip outer braces
  con = con:sub(2,-2)
  -- strip only leading % and \n, if they are in the first two characters
  con = con:gsub("^%s*%%?%s*","")
  -- if it is wrapped in \begin{align}...\end{align} or \begin{align*}...\end{align*}, replace the wrapping align or align* with $$\begin{aligned}...\end{aligned}$$
  con = con:gsub("\\begin{align%*?}(.-)\\end{align%*?",function (x) return "$$\\begin{aligned}" .. x:gsub("%s*$","") .. "\\end{aligned}$$" end)
  return pandoc.RawBlock('markdown',con,{class='maybe'})
end

local function replace_mayb_inline(el)
  -- Replace \mayb{...} with its contents
  -- get text between {} but not the braces, recognizing that there can be braces in the text
  local con = el.text:match("%b{}")
  -- strip outer braces
  con = con:sub(2,-2)
  -- strip only leading % and \n, if they are in the first two characters
  con = con:gsub("^%s*%%?%s*","")
  -- if it is wrapped in \begin{align}...\end{align} or \begin{align*}...\end{align*}, replace the wrapping align or align* with $$\begin{aligned}...\end{aligned}$$
  con = con:gsub("\\begin{align%*?}(.-)\\end{align%*?",function (x) return "$$\\begin{aligned}" .. x:gsub("%s*$","") .. "\\end{aligned}$$" end)
  local tex_contents = pandoc.RawInline('markdown',
    con,
    {class='maybe'}
  )
  return tex_contents
end

local function replace_examplemaybe(el)
  -- Replace \examplemaybe{title}{problem statement}{solution}{label} with Div with class example and sub div for the solution (the problem is the main text)
  -- Get the problem, solution, and label recognizing that there can be nested braces in the problem and solution
  local problem = el.text:match("{.-}{(.-)}{.-}{.-}")
  local solution = el.text:match("{.-}{.-}{(.-)}{.-}")
  local label = el.text:match("{.-}{.-}{.-}{(.-)}")
  -- For label, strip leading % and \n, if they are in the first two characters
  label = label:gsub("^%s*%%?%s*","")
  -- For label, strip any %
  label = label:gsub("%%","")
  -- For label, strip leading and trailing whitespace
  label = label:gsub("^%s*(.-)%s*$","%1")
  -- For each block in the problem statement and solution, walk with the block_filter
  local problem_blocks = pandoc.read(problem,'latex+raw_tex').blocks
  local solution_blocks = pandoc.read(solution,'latex+raw_tex').blocks
  for i = 1, #problem_blocks do
    problem_blocks[i] = pandoc.walk_block(
      problem_blocks[i],
      block_filter
    )
  end
  for i = 1, #solution_blocks do
    solution_blocks[i] = pandoc.walk_block(
      solution_blocks[i],
      block_filter
    )
  end
  -- return the Div with the problem and solution blocks
  -- I keep getting errors constructing Div elements from the blocks
  -- also add attribute h=label
  local example = pandoc.Div(
    {
      pandoc.Div(problem_blocks),
      pandoc.Div(
        solution_blocks,
        {class='example-solution'}
      )
    },
    {label,{'example'}}
  )
  example.attributes['h'] = label
  return example
end

local function pagerefer(el)
  local ref = el.text:match("\\pageref{(.-)}")
  return pandoc.RawInline('markdown',"[@" .. ref .. "]")
end

function RawInline(el)
  if starts_with('\\keyword', el.text) then
    return keyworder(el)
  elseif starts_with('\\cloze', el.text) then
    return clozer(el)
  elseif starts_with('\\ref', el.text) or starts_with('\\cref', el.text) or starts_with('\\autoref', el.text) or starts_with('\\eqref', el.text) then
    return referencer(el)
  elseif starts_with('\\myurl', el.text) then
    return urler(el)
  elseif starts_with('\\noindent', el.text) then
    return {}
  elseif starts_with('\\mpy{', el.text) then
    return mpyer(el)
  elseif starts_with('\\mc{', el.text) then
    return mcer(el)
  elseif starts_with('\\mb{', el.text) then
    return mber(el)
  elseif starts_with('\\path', el.text) then
    return mpyer(el)
  elseif starts_with('\\mykeys{', el.text) then
    return keyer(el)
  elseif starts_with('\\board',el.text) then
    return boarder_inline(el)
  elseif starts_with('\\index', el.text) then
    return {}
  elseif starts_with('\\phantom', el.text) then
    return {}
  elseif starts_with('\\hfil', el.text) then
    return {}
  elseif starts_with('\\hfill', el.text) then
    return {}
  elseif starts_with('\\kern', el.text) then
    return {}
  elseif starts_with('\\p ', el.text) then
    return {}
  elseif starts_with('\\pageref', el.text) then
    return pagerefer(el)
  elseif starts_with('\\maybeeqn', el.text) then
    return replace_maybeeqn_inline(el)
  elseif starts_with('\\maybeeq', el.text) then
    return replace_maybeeq_inline(el)
  elseif starts_with('\\mayb{', el.text) then
    return replace_mayb_inline(el)
  else
    return el
  end
end

function RawBlock(el)
  if starts_with('\\begin{myexample}', el.text) then
    local id = el.text:match("\\label{(.-)}")
    local converted = replace_myexample(el)
    return pandoc.Div(converted,{id=id, class='example'})
  elseif starts_with('\\begin{myexamplealways}', el.text) then
    local id = el.text:match("\\label{(.-)}")
    local converted = replace_myexamplealways(el)
    return pandoc.Div(converted,{id=id, class='example'})
  elseif starts_with('\\begin{Definition}', el.text) then
    return replace_Definition(el)
  elseif starts_with('\\begin{infobox}', el.text) then
    return replace_infobox(el)
  elseif starts_with('\\begin{exercise}', el.text) then
    return replace_exercise(el)
  elseif starts_with('\\begin{solution}', el.text) then
    return replace_solution(el)
  elseif starts_with('\\cloze', el.text) then
    return clozer_block(el)
  elseif starts_with('\\clearpage', el.text) then
    return {}
  elseif starts_with('\\centering', el.text) then
    return {}
  elseif starts_with('\\phantom', el.text) then
    return {}
  elseif starts_with('\\mynewslide', el.text) then
    return pandoc.Para(' ')
  elseif starts_with('\\setlength', el.text) then
    return pandoc.Para(' ')
  elseif starts_with('\\subfile', el.text) then
    return replace_subfile(el)
  elseif starts_with('\\input', el.text) then
    return replace_input(el)
  elseif starts_with('\\resource', el.text) then
    return replace_resource(el)
  elseif starts_with('\\begin{todolist}', el.text) then
    return replace_todolist(el)
  elseif starts_with('\\begin{subequations}', el.text) then
    return strip_environment(el,'subequations')
  elseif starts_with('\\board',el.text) then
    return boarder(el)
  elseif starts_with('\\begin{slides',el.text) then
    return {}
  elseif starts_with('\\hfil', el.text) then
    return {}
  elseif starts_with('\\vspace{', el.text) then
    return {}
  elseif starts_with('\\smallskip', el.text) then
    return {}
  elseif starts_with('\\begin{textbook', el.text) then
    return replace_textbook(el)
  elseif starts_with('\\begin{definition}', el.text) then
    return replace_definition(el)
  elseif starts_with('\\begin{theorem}', el.text) then
    return replace_theorem(el)
  elseif starts_with('\\begin{lemma}', el.text) then
    return replace_lemma(el)
  elseif starts_with('\\notes', el.text) then
    return replace_notes(el)
  elseif starts_with('\\maybeeqn{', el.text) then
    return replace_maybeeqn(el)
  elseif starts_with('\\maybeeq{', el.text) then
    return replace_maybeeq(el)
  elseif starts_with('\\mayb{', el.text) then
    return replace_mayb(el)
  elseif starts_with('\\examplemaybe', el.text) then
    return replace_examplemaybe(el)
  else
    return el
  end
end

-- The main function to process headers
function Header(elem)
  -- Promote headers by one level (except level 1 headers)
  if elem.level > 1 then
    elem.level = elem.level - 1
  end

  -- If the header is not a section or subsection, return it as is
  if elem.level > 2 then
    return elem
  end
  -- Generate a unique random two-character alphanumeric string
  local unique_str = unique_random_string()

  -- Add the attribute `h` with the unique string to the header
  elem.attributes['h'] = unique_str
  
  return elem
end

-- table-to-html.lua
function Table (tbl)
  local tbl = pandoc.utils.to_simple_table(tbl)

  local function render_row (row)
    local result = "<tr>"
    for _, cell in ipairs(row) do
      -- Write the cell to html with MathJax support for math (i.e., LaTeX math)
      -- cell = pandoc.walk_block(cell, block_filter)
      local doc = pandoc.Pandoc(cell)
      cell = pandoc.write(doc, "html+tex_math_dollars+raw_tex")
      result = result .. "\n\t<td>" .. pandoc.utils.stringify(cell) .. "</td>"
    end
    result = result .. "\n</tr>"
    return result
  end

  local result = "<table>\n"
  if tbl.header ~= nil then
    for _, header in ipairs(tbl.header) do
      result = result .. "<tr>"
      for _, h in ipairs(header) do
        result = result .. "<th>" .. pandoc.utils.stringify(h) .. "</th>"
      end
      result = result .. "\n</tr>\n"
    end
  end
  for _, row in ipairs(tbl.rows) do
    result = result .. render_row(row)
  end
  result = result .. "\n</table>"

  return pandoc.RawBlock("markdown", result)
end

function OrderedList (el)
  -- If there's a Table anywhere in the OrderedList items or subitems (for nested OrderedLists), convert it to HTML via the Table function
  for i, item in ipairs(el.content) do
    -- If the item is a Table, convert it to HTML
    if item.t == "Table" then
      el.content[i] = Table(item)
    end
    -- If the item is a List, recursively call this function
    if item.t == "OrderedList" then
      el.content[i] = OrderedList(item)
    end
  end
  -- Now run the default OrderedList function
  return el
end

return {
  {RawInline = RawInline, OrderedList = OrderedList, Table = Table, RawBlock = RawBlock, Header = Header}
}
