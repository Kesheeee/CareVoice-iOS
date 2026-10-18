import { authClient } from './auth';
export type Suggestion={type:string;id:string;title:string;plain:string;quote?:string;url?:string;why:string};
export type Safety={signal:string;route:string;contact?:string};
export type AskResponse={safety?:Safety;suggestions:Suggestion[];content_fingerprint?:string};
export const isAskConfigured=true;
export async function ask(message:string,language:string):Promise<AskResponse>{
 const {data:{session}}=await authClient.auth.getSession();
 if(!session)throw new Error('auth');
 const {data,error}=await authClient.functions.invoke('ask-carevoice',{body:{message,language},signal:AbortSignal.timeout(60000)});
 if(error){let code='unavailable';try{code=(await (error as any).context?.json())?.code||code;}catch{}throw new Error(code);}
 if(!data||!Array.isArray(data.suggestions))throw new Error('invalid_response');
 return data;
}
