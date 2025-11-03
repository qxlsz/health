/**
 * Supabase Edge Function for Sleep Analysis
 * Calls the Python analysis service to process sleep data
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const PYTHON_SERVICE_URL = Deno.env.get('PYTHON_SERVICE_URL') || 'http://python-service:8000'

interface SleepData {
  sessions?: any[]
  stages?: any[]
  start_time?: string
  end_time?: string
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    // Get authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Verify user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const sleepData: SleepData = await req.json()

    // Call Python analysis service
    const analysisResponse = await fetch(`${PYTHON_SERVICE_URL}/analyze`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(sleepData),
    })

    if (!analysisResponse.ok) {
      // Fallback to simple analysis if Python service is unavailable
      console.log('Python service unavailable, using fallback')
      const fallbackResult = simpleAnalysis(sleepData)
      return new Response(
        JSON.stringify(fallbackResult),
        {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      )
    }

    const analysisResult = await analysisResponse.json()

    // Store analysis results in database (optional)
    // await supabaseClient
    //   .from('sleep_analysis')
    //   .insert({
    //     user_id: user.id,
    //     analysis_data: analysisResult,
    //     created_at: new Date().toISOString(),
    //   })

    return new Response(
      JSON.stringify(analysisResult),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  }
})

/**
 * Simple fallback analysis if Python service is unavailable
 */
function simpleAnalysis(sleepData: SleepData) {
  const stages = sleepData.stages || []
  const totalSleep = stages
    .filter(s => s.type !== 'AWAKE')
    .reduce((sum, s) => sum + (s.duration || 0), 0)
  
  const rem = stages
    .filter(s => s.type === 'REM')
    .reduce((sum, s) => sum + (s.duration || 0), 0)
  
  const deep = stages
    .filter(s => s.type === 'DEEP')
    .reduce((sum, s) => sum + (s.duration || 0), 0)

  return {
    efficiency: totalSleep > 0 ? 85.0 : 0.0,
    total_sleep_duration: totalSleep,
    rem_percentage: totalSleep > 0 ? (rem / totalSleep * 100) : 0.0,
    deep_sleep_percentage: totalSleep > 0 ? (deep / totalSleep * 100) : 0.0,
    light_sleep_percentage: totalSleep > 0 
      ? ((totalSleep - rem - deep) / totalSleep * 100) 
      : 0.0,
    awake_percentage: 15.0,
    sleep_score: 75.0,
    note: 'Fallback analysis - Python service unavailable',
  }
}

