#pragma semicolon 1
#pragma newdecls required

enum struct VScriptCmd
{
    char Code[8192];
    void Append(const char[] str)
    {
        StrCat(this.Code, sizeof(this.Code), str);
    }
    
    void Clear()
    {
        this.Code = "";
    }
    
    void Run(int entity)
    {
        static char str[8192];
        FormatEx(str, sizeof(str), "if(self!=null && self.IsValid())%s", this.Code);
        RunScriptCode(entity, str);
    }
    
    int Run_ReturnInt(int entity)
    {
        static char str[8192];
        FormatEx(str, sizeof(str), "if(self!=null && self.IsValid())NetProps.SetPropString(activator, `m_iszMessage`, %s.tostring())", this.Code);
        return RunScriptCode_ReturnInt(entity, str);
    }
    
    float Run_ReturnFloat(int entity)
    {
        static char str[8192];
        FormatEx(str, sizeof(str), "if(self!=null && self.IsValid())NetProps.SetPropString(activator, `m_iszMessage`, %s.tostring())", this.Code);
        return RunScriptCode_ReturnFloat(entity, str);
    }
    
    int Run_ReturnString(int entity, char[] buffer, int size)
    {
        static char str[8192];
        FormatEx(str, sizeof(str), "if(self!=null && self.IsValid())NetProps.SetPropString(activator, `m_iszMessage`, %s.tostring())", this.Code);
        return RunScriptCode_ReturnString(entity, str, buffer, size);
    }
    
    void Run_ReturnVector(int entity, float buffer[3])
    {
        static char str[8192];
        FormatEx(str, sizeof(str), "if(self!=null && self.IsValid())NetProps.SetPropString(activator, `m_iszMessage`, %s.tostring())", this.Code);
        RunScriptCode_ReturnVector(entity, str, buffer);
    }
}

void RunScriptCode(int entity, const char[] code)
{
	SetVariantString(code);
	AcceptEntityInput(entity, "RunScriptCode");
}

static int g_iScriptSlave = INVALID_ENT;
// Set the m_iszMessage property of "activator" in the script code to the return value
int RunScriptCode_ReturnInt(int entity, const char[] code)
{
	if (EntRefToEntIndex(g_iScriptSlave) == INVALID_ENT)
	{
		g_iScriptSlave = EntIndexToEntRef(CreateEntityByName("game_text"));
	}
	
	SetVariantString(code);
	AcceptEntityInput(entity, "RunScriptCode", g_iScriptSlave);
	static char name[128];
	GetEntPropString(g_iScriptSlave, Prop_Data, "m_iszMessage", name, sizeof(name));
	return StringToInt(name);
}

// Set the m_iszMessage property of "activator" in the script code to the return value
float RunScriptCode_ReturnFloat(int entity, const char[] code)
{
	if (EntRefToEntIndex(g_iScriptSlave) == INVALID_ENT)
	{
		g_iScriptSlave = EntIndexToEntRef(CreateEntityByName("game_text"));
	}
	
	SetVariantString(code);
	AcceptEntityInput(entity, "RunScriptCode", g_iScriptSlave);
	static char name[128];
	GetEntPropString(g_iScriptSlave, Prop_Data, "m_iszMessage", name, sizeof(name));
	return StringToFloat(name);
}

// Set the m_iszMessage property of "activator" in the script code to the return value
int RunScriptCode_ReturnString(int entity, const char[] code, char[] buffer, int size)
{
	if (EntRefToEntIndex(g_iScriptSlave) == INVALID_ENT)
	{
		g_iScriptSlave = EntIndexToEntRef(CreateEntityByName("game_text"));
	}
	
	SetVariantString(code);
	AcceptEntityInput(entity, "RunScriptCode", g_iScriptSlave);
	static char name[128];
	GetEntPropString(g_iScriptSlave, Prop_Data, "m_iszMessage", name, sizeof(name));
	return strcopy(buffer, size, name);
}

// Set the m_iszMessage property of "activator" in the script code to the return value
void RunScriptCode_ReturnVector(int entity, const char[] code, float buffer[3])
{
	if (EntRefToEntIndex(g_iScriptSlave) == INVALID_ENT)
	{
		g_iScriptSlave = EntIndexToEntRef(CreateEntityByName("game_text"));
	}
	
	SetVariantString(code);
	AcceptEntityInput(entity, "RunScriptCode", g_iScriptSlave);
	static char name[128];
	GetEntPropString(g_iScriptSlave, Prop_Data, "m_iszMessage", name, sizeof(name));
	ReplaceString(name, sizeof(name), "(vector : (", "", false);
	ReplaceString(name, sizeof(name), ")", "", false);
	char buffers[3][32];
	int count = ExplodeString(name, ", ", buffers, sizeof(buffers), sizeof(buffers[]), true);
	for (int i = 0; i < count; i++)
	{
		buffer[i] = StringToFloat(buffers[i]);
	}
}
